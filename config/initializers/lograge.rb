# frozen_string_literal: true

# Only use Lograge for Rails
unless Gitlab::Runtime.sidekiq?
  Rails.application.reloader.to_prepare do
    filename = File.join(Rails.root, 'log', "#{Rails.env}_json.log")

    Rails.application.configure do
      config.lograge.enabled = true
      # Store the lograge JSON files in a separate file
      config.lograge.keep_original_rails_log = Gitlab::Utils.to_boolean(ENV.fetch('UNSTRUCTURED_RAILS_LOG', 'true'))
      # Don't use the Logstash formatter since this requires logstash-event, an
      # unmaintained gem that monkey patches `Time`
      config.lograge.formatter = Lograge::Formatters::Json.new
      config.lograge.logger = ActiveSupport::Logger.new(filename)
      config.lograge.before_format = lambda do |data, payload|
        data.delete(:error)
        data[:db_duration_s] = Gitlab::Utils.ms_to_round_sec(data.delete(:db)) if data[:db]
        data[:view_duration_s] = Gitlab::Utils.ms_to_round_sec(data.delete(:view)) if data[:view]
        data[:duration_s] = Gitlab::Utils.ms_to_round_sec(data.delete(:duration)) if data[:duration]
        data[:location] = Gitlab::Utils.removes_sensitive_data_from_url(data[:location]) if data[:location]

        # Remove empty hashes to prevent type mismatches
        # These are set to empty hashes in Lograge's ActionCable subscriber
        # https://github.com/roidrage/lograge/blob/v0.11.2/lib/lograge/log_subscribers/action_cable.rb#L14-L16
        %i(method path format).each do |key|
          data[key] = nil if data[key] == {}
        end

        data
      end

      # This isn't a user-reachable controller; we use it to check for a
      # valid CSRF token in the API
      config.lograge.ignore_actions = ['Gitlab::RequestForgeryProtection::Controller#index']

      # Add request parameters to log output
      config.lograge.custom_options = Gitlab::Lograge::CustomOptions
    end
  end
end
