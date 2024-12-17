# frozen_string_literal: true

require 'tmpdir'

module QA
  module Runtime
    module Fixtures
      include Support::API

      TemplateNotFoundError = Class.new(RuntimeError)

      def fetch_template_from_api(api_path, key)
        request = Runtime::API::Request.new(api_client, "/templates/#{api_path}/#{key}")
        response = get(request.url)

        unless response.code == HTTP_STATUS_OK
          raise TemplateNotFoundError,
            "Template at #{request.mask_url} could not be found (#{response.code}): `#{response}`."
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

      def read_fixture(fixture_path, file_name)
        File.read(Runtime::Path.fixture(fixture_path, file_name))
      end

      def read_ee_fixture(fixture_path, file_name)
        File.read(File.join(EE::Runtime::Path.fixtures_path, fixture_path, file_name))
      end

      private

      def api_client
        @api_client ||= User::Store.test_user.api_client
      end
    end
  end
end

QA::Runtime::Fixtures.prepend_mod_with('Runtime::Fixtures', namespace: QA)
