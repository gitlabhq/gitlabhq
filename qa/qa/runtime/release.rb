module QA
  module Runtime
    ##
    # Class that is responsible for plugging CE/EE extensions in, depending on
    # existence of EE module.
    #
    # We need that to reduce the probability of conflicts when merging
    # CE to EE.
    #
    class Release
      def initialize
        require "qa/#{version.downcase}/strategy"
      end

      def version
        @version ||= File.directory?("#{__dir__}/../ee") ? :EE : :CE
      end

      def strategy
        QA.const_get("QA::#{version}::Strategy")
      end

      def self.method_missing(name, *args)
        self.new.strategy.public_send(name, *args) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
