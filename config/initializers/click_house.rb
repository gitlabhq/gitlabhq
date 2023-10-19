# frozen_string_literal: true

return unless File.exist?(Rails.root.join('config/click_house.yml'))

raw_config = Rails.application.config_for(:click_house)

return if raw_config.blank?

ClickHouse::Client.configure do |config|
  raw_config.each do |database_identifier, db_config|
    config.register_database(database_identifier,
      database: db_config[:database],
      url: db_config[:url],
      username: db_config[:username],
      password: db_config[:password],
      variables: db_config[:variables] || {}
    )
  end

  config.logger = ::ClickHouse::Logger.build
  config.log_proc = ->(query) do
    query_output =
      Rails.env.production? ? query.to_redacted_sql : query.to_sql
    structured_log(query_output)
  end

  config.json_parser = Gitlab::Json
  config.http_post_proc = ->(url, headers, body) do
    options = {
      multipart: true,
      headers: headers,
      allow_local_requests: true
    }

    body_key = body.is_a?(IO) ? :body_stream : :body
    options[body_key] = body

    response = Gitlab::HTTP.post(url, options)
    ClickHouse::Client::Response.new(response.body, response.code, response.headers)
  end
end

def structured_log(query_string)
  { query: query_string, correlation_id: Labkit::Correlation::CorrelationId.current_id.to_s }
end
