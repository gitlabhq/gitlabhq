# frozen_string_literal: true

module Gitlab
  module Environment
    def self.hostname
      @hostname ||= ENV['HOSTNAME'] || Socket.gethostname
    end

    # Check whether codebase is going through static verification
    # in order to skip executing parts of the codebase
    #
    # @return [Boolean] Is the code going through static verification?
    def self.static_verification?
      static_verification = Gitlab::Utils.to_boolean(ENV['STATIC_VERIFICATION'], default: false)
      env_production = ENV['RAILS_ENV'] == 'production'

      warn '[WARNING] Static Verification bypass is enabled in Production.' if static_verification && env_production

      static_verification
    end
  end
end
