require 'ruby-prof'
require_dependency 'gitlab/request_profiler'

module Gitlab
  module RequestProfiler
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if profile?(env)
          call_with_profiling(env)
        else
          @app.call(env)
        end
      end

      def profile?(env)
        header_token = env['HTTP_X_PROFILE_TOKEN']
        return unless header_token.present?

        profile_token = RequestProfiler.profile_token
        return unless profile_token.present?

        header_token == profile_token
      end

      def call_with_profiling(env)
        ret = nil
        result = RubyProf::Profile.profile do
          ret = catch(:warden) do
            @app.call(env)
          end
        end

        printer   = RubyProf::CallStackPrinter.new(result)
        file_name = "#{env['PATH_INFO'].tr('/', '|')}_#{Time.current.to_i}.html"
        file_path = "#{PROFILES_DIR}/#{file_name}"

        FileUtils.mkdir_p(PROFILES_DIR)
        File.open(file_path, 'wb') do |file|
          printer.print(file)
        end

        if ret.is_a?(Array)
          ret
        else
          throw(:warden, ret)
        end
      end
    end
  end
end
