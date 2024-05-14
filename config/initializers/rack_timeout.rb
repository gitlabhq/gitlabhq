# frozen_string_literal: true

# Puma doesn't have any timeout mechanism for terminating long-running
# requests, to make sure that server is not paralyzed by long-running
# or stuck queries, we add a request timeout which terminates the
# request after 60 seconds. This may be dangerous in some situations
# (https://github.com/zombocom/rack-timeout/blob/master/doc/exceptions.md)
# and it's used only as the last resort. In such case this termination is
# logged and we should fix the potential timeout issue in the code itself.

if Gitlab::Runtime.puma? && !Rails.env.test?
  Rack::Timeout::Logger.level = Logger::ERROR

  Gitlab::Application.configure do |config|
    config.middleware.insert_before(Rack::Runtime, Rack::Timeout,
      service_timeout: ENV.fetch('GITLAB_RAILS_RACK_TIMEOUT', 60).to_i,
      wait_timeout: ENV.fetch('GITLAB_RAILS_WAIT_TIMEOUT', 90).to_i)
  end

  observer = Gitlab::Cluster::RackTimeoutObserver.new
  Rack::Timeout.register_state_change_observer(:gitlab_rack_timeout, &observer.callback)
end

unless Gitlab::Utils.to_boolean(ENV['GITLAB_RAILS_RACK_TIMEOUT_ENABLE_LOGGING'], default: true)
  Rack::Timeout::Logger.disable
end
