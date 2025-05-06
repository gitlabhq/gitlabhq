# frozen_string_literal: true

module Net
  class HTTPResponse
    module FinishOverride
      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- This is a Monkey Patch
      def finish
        if Gitlab.config.gitlab.log_decompressed_response_bytesize > 0 &&
            @inflate.total_out > Gitlab.config.gitlab.log_decompressed_response_bytesize
          Gitlab::AppJsonLogger.debug(message: 'net/http: response decompressed', size: @inflate.total_out,
            caller: Gitlab::BacktraceCleaner.clean_backtrace(caller))
        end

        super
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end

    # Limit the maximum decompression size
    class Inflater
      prepend FinishOverride
    end
  end
end
