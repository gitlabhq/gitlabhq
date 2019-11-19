# frozen_string_literal: true

require 'tmpdir'

module QA
  module Runtime
    module Fixtures
      include Support::Api

      TemplateNotFoundError = Class.new(RuntimeError)

      def fetch_template_from_api(api_path, key)
        request = Runtime::API::Request.new(api_client, "/templates/#{api_path}/#{key}")
        response = get(request.url)

        unless response.code == HTTP_STATUS_OK
          raise TemplateNotFoundError, "Template at #{request.mask_url} could not be found (#{response.code}): `#{response}`."
        end

        parse_body(response)[:content]
      end

      def with_fixtures(fixtures)
        dir = Dir.mktmpdir
        fixtures.each do |file_def|
          path = File.join(dir, file_def[:file_path])
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, file_def[:content])
        end

        yield dir
      ensure
        FileUtils.remove_entry(dir, true)
      end

      private

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab)
      end
    end
  end
end
