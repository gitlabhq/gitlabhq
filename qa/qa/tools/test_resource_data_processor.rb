# frozen_string_literal: true

# This script collects all resources created during each test execution
# Save the data and write it to a JSON file at the end of suite

module QA
  module Tools
    class TestResourceDataProcessor
      include Singleton

      def initialize
        @resources = Hash.new { |hsh, key| hsh[key] = [] }
      end

      class << self
        delegate :collect, :write_to_file, :resources, to: :instance
      end

      # @return [Hash<String, Array>]
      attr_reader :resources

      # Collecting resources created in E2E tests
      # Data is a Hash of resources with keys as resource type (group, project, issue, etc.)
      # Each type contains an array of resource object (hash) of the same type
      # E.g: { "QA::Resource::Project": [ { info: 'foo', api_path: '/foo'}, {...} ] }
      #
      # @param [QA::Resource::Base] resource fabricated resource
      # @param [String] info resource info
      # @param [Symbol] method fabrication method, api or browser_ui
      # @param [Integer] time fabrication time
      # @return [Hash]
      def collect(resource:, info:, fabrication_method:, fabrication_time:)
        api_path = resource_api_path(resource)
        type = resource.class.name

        resources[type] << {
          info: info,
          api_path: api_path,
          fabrication_method: fabrication_method,
          fabrication_time: fabrication_time,
          http_method: resource.api_fabrication_http_method || :post,
          timestamp: Time.now.to_s
        }
      end

      # If JSON file exists and not empty, read and load file content
      # Merge what is saved in @resources into the content from file
      # Overwrite file content with the new data hash
      # Otherwise create file and write data hash to file for the first time
      #
      # @return [void]
      def write_to_file(suite_failed)
        return if resources.empty?

        start_str = mark_as_failed?(suite_failed) ? 'failed-test-resources' : 'test-resources'
        file_name = Runtime::Env.running_in_ci? ? "#{start_str}-#{SecureRandom.hex(3)}.json" : "#{start_str}.json"
        file = Pathname.new(File.join(Runtime::Path.qa_root, 'tmp', file_name))
        FileUtils.mkdir_p(file.dirname)

        data = resources.deep_dup
        # merge existing json if present
        JSON.parse(File.read(file)).deep_merge!(data) { |_, val, other_val| val + other_val } if file.exist?

        File.write(file, JSON.pretty_generate(data))
      end

      private

      # Check if resource file should be marked as failed
      #
      # @param [Boolean] suite_failed
      # @return [Boolean]
      def mark_as_failed?(suite_failed)
        return suite_failed unless ::Gitlab::QA::Runtime::Env.retry_failed_specs?

        # if suite ran in the initial run, do not mark resource as failed even if suite failed
        Runtime::Env.rspec_retried? ? suite_failed : false
      end

      # Determine resource api path or return default value
      # Some resources fabricated via UI can raise no attribute error
      #
      # @param [QA::Resource::Base] resource
      # @return [String]
      def resource_api_path(resource)
        default = 'Cannot find resource API path'

        if resource.respond_to?(:api_delete_path)
          resource.api_delete_path.gsub('%2F', '/')
        elsif resource.respond_to?(:api_get_path)
          resource.api_get_path.gsub('%2F', '/')
        else
          default
        end
      rescue QA::Resource::Base::NoValueError, QA::Resource::Errors::ResourceNotFoundError
        default
      end
    end
  end
end
