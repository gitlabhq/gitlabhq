# Only use Lograge for Rails
unless Gitlab::Runtime.sidekiq?
  filename = File.join(Rails.root, 'log', "#{Rails.env}_json.log")

  Rails.application.configure do
    config.lograge.enabled = true
    # Store the lograge JSON files in a separate file
    config.lograge.keep_original_rails_log = true
    # Don't use the Logstash formatter since this requires logstash-event, an
    # unmaintained gem that monkey patches `Time`
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.logger = ActiveSupport::Logger.new(filename)
    config.lograge.before_format = lambda do |data, payload|
      data.delete(:error)
      data[:db_duration_s] = Gitlab::Utils.ms_to_round_sec(data.delete(:db))
      data[:view_duration_s] = Gitlab::Utils.ms_to_round_sec(data.delete(:view))
      data[:duration_s] = Gitlab::Utils.ms_to_round_sec(data.delete(:duration))

      data
    end

    # This isn't a user-reachable controller; we use it to check for a
    # valid CSRF token in the API
    config.lograge.ignore_actions = ['Gitlab::RequestForgeryProtection::Controller#index']

    # Add request parameters to log output
    config.lograge.custom_options = Gitlab::Lograge::CustomOptions
  end
end
