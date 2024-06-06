# frozen_string_literal: true

module Gitlab
  module Environment
    extend ::Gitlab::Utils::StrongMemoize

    def self.hostname
      strong_memoize(:hostname) do
        ENV['HOSTNAME'] || Socket.gethostname
      end
    end

    # Check whether codebase is going through static verification
    # in order to skip executing parts of the codebase
    #
    # @return [Boolean] Is the code going through static verification?
    def self.static_verification?
      static_verification = Gitlab::Utils.to_boolean(ENV['STATIC_VERIFICATION'], default: false)

      if static_verification && Rails.env.production?
        warn '[WARNING] Static Verification bypass is enabled in Production.'
      end

      static_verification
    end
  end
end
