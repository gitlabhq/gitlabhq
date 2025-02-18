# frozen_string_literal: true

module ActiveContext
  class Logger
    ANONYMOUS = '<Anonymous>'

    class << self
      def debug(**kwargs)
        log(:debug, **kwargs)
      end

      def info(**kwargs)
        log(:info, **kwargs)
      end

      def warn(**kwargs)
        log(:warn, **kwargs)
      end

      def error(**kwargs)
        log(:error, **kwargs)
      end

      def fatal(**kwargs)
        log(:fatal, **kwargs)
      end

      def exception(exception, **kwargs)
        payload = {
          exception_class: exception.class.name,
          exception_message: exception.message,
          exception_backtrace: exception.backtrace
        }.merge(kwargs)

        error(**payload)
      end

      private

      def log(severity, **kwargs)
        logger = ActiveContext::Config.logger

        return unless logger

        payload = build_structured_payload(**kwargs)
        case severity
        when :debug then logger.debug(payload)
        when :info  then logger.info(payload)
        when :warn  then logger.warn(payload)
        when :error then logger.error(payload)
        when :fatal then logger.fatal(payload)
        end
      end

      def build_structured_payload(**params)
        { class: self.class.name || ANONYMOUS }.merge(params).stringify_keys
      end
    end
  end
end
