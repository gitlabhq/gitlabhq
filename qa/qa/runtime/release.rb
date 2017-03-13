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
      def initialize(variant = nil)
        @version = variant || version

        begin
          require "qa/#{@version.downcase}/strategy"
        rescue LoadError
          # noop
        end
      end

      def version
        File.directory?("#{__dir__}/../ee") ? :EE : :CE
      end

      def has_strategy?
        QA.const_defined?("QA::#{@version}::Strategy")
      end

      def strategy
        QA.const_get("QA::#{@version}::Strategy")
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
