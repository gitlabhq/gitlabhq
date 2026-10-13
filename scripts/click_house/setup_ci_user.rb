#!/usr/bin/env ruby
# frozen_string_literal: true

# Bootstraps the CI ClickHouse service with the user, role and grants documented in
# doc/integration/clickhouse.md, so a spec can't pass in CI on a privilege that production
# lacks. Runs as `default`, the only account the service starts with ACCESS MANAGEMENT.

require 'click_house/client'
require 'net/http'

DOC_PATH = 'doc/integration/clickhouse.md'
PRODUCTION_DB = 'gitlab_clickhouse_main_production'
GRANT_BLOCK = /gitlab-clickhouse-grants:start.*?```sql\n(.*?)```/m

DATABASE = ENV.fetch('CLICKHOUSE_DB', 'gitlab_clickhouse_test')
PASSWORD = ENV.fetch('GITLAB_CLICKHOUSE_PASSWORD')

ClickHouse::Client.configure do |config|
  config.register_database(:admin,
    database: DATABASE,
    url: ENV.fetch('CLICKHOUSE_HOST_URL', 'http://clickhouse:8123'),
    username: ENV.fetch('CLICKHOUSE_USER', 'default'),
    password: '',
    variables: { mutations_sync: 1 }
  )

  config.http_post_proc = ->(url, headers, body) do
    # ClickHouse only reads params out of a multipart body, so pass them on the query string
    # instead. Gitlab::HTTP sends multipart; plain Net::HTTP would not.
    uri = URI(url)
    uri.query = [uri.query, URI.encode_www_form(body)].compact.join('&')

    request = Net::HTTP::Post.new(uri, headers)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    ClickHouse::Client::Response.new(response.body, response.code.to_i, response.each_header.to_h)
  end

  # The gem logs every statement through log_proc, which would put the new user's password
  # in the job log.
  config.logger = ::Logger.new(IO::NULL)
end

def execute(sql, attempts = 60)
  ClickHouse::Client.execute(sql, :admin)
rescue SystemCallError, IOError # the service container may still be starting up
  raise if (attempts -= 1) <= 0

  sleep 1
  retry
end

def documented_statements
  sql = File.read(DOC_PATH)[GRANT_BLOCK, 1]

  # Fail loudly rather than bootstrap a half-privileged user if the block moves or is reworded.
  abort("No `gitlab-clickhouse-grants` SQL block in #{DOC_PATH}") unless sql&.include?(PRODUCTION_DB)

  sql.lines.map(&:strip).reject(&:empty?)
end

documented_statements.each do |statement|
  execute(statement.gsub(PRODUCTION_DB, DATABASE).gsub('PASSWORD_HERE', PASSWORD).chomp(';'))
end
