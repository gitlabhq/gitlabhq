# frozen_string_literal: true

# This script collects all resources created during each test execution
# Save the data and write it to a JSON file at the end of suite

module QA
  module Tools
    class TestResourceDataProcessor
      @resources ||= Hash.new { |hsh, key| hsh[key] = [] }

      class << self
        # Ignoring rspec-mocks, sandbox, user and fork resources
        # TODO: Will need to figure out which user resources can be collected, ignore for now
        #
        # Collecting resources created in E2E tests
        # Data is a Hash of resources with keys as resource type (group, project, issue, etc.)
        # Each type contains an array of resource object (hash) of the same type
        # E.g: { "QA::Resource::Project": [ { info: 'foo', api_path: '/foo'}, {...} ] }
        def collect(resource, info)
          return if resource.api_response.nil? ||
            resource.is_a?(RSpec::Mocks::Double) ||
            resource.is_a?(Resource::Sandbox) ||
            resource.is_a?(Resource::User) ||
            resource.is_a?(Resource::Fork)

          api_path = if resource.respond_to?(:api_delete_path)
                       resource.api_delete_path.gsub('%2F', '/')
                     elsif resource.respond_to?(:api_get_path)
                       resource.api_get_path.gsub('%2F', '/')
                     else
                       'Cannot find resource API path'
                     end

          type = resource.class.name

          @resources[type] << { info: info, api_path: api_path }
        end

        # If JSON file exists and not empty, read and load file content
        # Merge what is saved in @resources into the content from file
        # Overwrite file content with the new data hash
        # Otherwise create file and write data hash to file for the first time
        def write_to_file
          return if @resources.empty?

          file = Runtime::Env.test_resources_created_filepath
          FileUtils.mkdir_p('tmp/')
          FileUtils.touch(file)
          data = nil

          if File.zero?(file)
            data = @resources
          else
            data = JSON.parse(File.read(file))

            @resources.each_pair do |key, val|
              data[key].nil? ? data[key] = val : val.each { |item| data[key] << item }
            end
          end

          File.open(file, 'w') { |f| f.write(JSON.pretty_generate(data.each_value(&:uniq!))) }
        end
      end
    end
  end
end
