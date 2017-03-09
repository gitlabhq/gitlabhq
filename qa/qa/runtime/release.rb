module QA
  module Runtime
    ##
    # Class that is responsible for plugging CE/EE extensions in, depending on
    # environment variable GITLAB_RELEASE that should be present in the runtime
    # environment.
    #
    # We need that to reduce the probability of conflicts when merging
    # CE to EE.
    #
    class Release
      UnspecifiedReleaseError = Class.new(StandardError)

      def initialize(version = ENV['GITLAB_RELEASE'])
        @version = version.to_s.upcase

        unless %w[CE EE].include?(@version)
          raise UnspecifiedReleaseError, 'GITLAB_RELEASE env not defined!'
        end

        begin
          require "#{version.downcase}/strategy"
        rescue LoadError
          # noop
        end
      end

      def has_strategy?
        QA.const_defined?("#{@version}::Strategy")
      end

      def strategy
        QA.const_get("#{@version}::Strategy")
      end

      def self.method_missing(name, *args)
        @release ||= self.new

        if @release.has_strategy?
          @release.strategy.public_send(name, *args)
        end
      end
    end
  end
end
