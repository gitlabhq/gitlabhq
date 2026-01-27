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
    redacted_sql = query.to_redacted_sql # call it to capture issues with redacted sql in non-production environments
    query_output =
      Rails.env.production? ? redacted_sql : query.to_sql
    structured_log(query_output)
  end

  config.json_parser = Gitlab::Json
  config.http_post_proc = ClickHouse::HttpClient.build_post_proc
end

def structured_log(query_string)
  { query: query_string, correlation_id: Labkit::Correlation::CorrelationId.current_id.to_s }
end
