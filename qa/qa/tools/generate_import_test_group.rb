# frozen_string_literal: true

require "etc"

module QA
  module Tools
    # Helper to generate group with projects for Direct Transfer testing
    #
    class GenerateImportTestGroup
      def initialize(
        project_tar_path: Runtime::Path.fixture('export.tar.gz'),
        group_path: "import-test",
        project_copies: 10,
        import_wait: 60,
        parallel_imports: Etc.nprocessors
      )
        @project_tar_path = project_tar_path
        @group_path = group_path
        @project_copies = project_copies
        @import_wait = import_wait
        @parallel_imports = parallel_imports
        @logger = Runtime::Logger.logger
      end

      # Generate group with projects
      #
      # @return [void]
      def generate
        validate_tar_path

        logger.info("Creating import-test group with #{project_copies} copies of '#{project_tar_path}' project")
        create_group

        Parallel.each((1..project_copies), in_threads: parallel_imports) do |copy|
          name = "imported-project-#{SecureRandom.hex(8)}"
          logger.info("Fabricating project copy nr: #{copy} with name '#{name}'")
          Resource::ImportProject.fabricate_via_api! do |project|
            project.file_path = project_tar_path
            project.api_client = api_client
            project.import_wait_duration = import_wait
            project.name = name
            project.group = group
          end
        end
      end

      private

      attr_reader :project_tar_path,
        :group_path,
        :project_copies,
        :import_wait,
        :parallel_imports,
        :logger

      # API client
      #
      # @return [Runtime::API::Client]
      def api_client
        @api_client ||= Runtime::API::Client.new(
          :gitlab,
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'] || raise("GITLAB_QA_ACCESS_TOKEN required")
        )
      end

      # Create group with all subgroups
      #
      # @return [<Resource::Sandbox, Resource::Group>]
      def group
        return @group if defined?(@group)

        paths = group_path.split("/")
        sandbox = create(:sandbox, path: paths.first)
        return @group = sandbox if paths.size == 1

        @group = paths[1..].each_with_object([sandbox]) do |path, arr|
          arr << create(:group, parent: arr.last, path: path)
        end.last
      end
      alias_method :create_group, :group

      # Create group resource
      #
      # @param [Symbol] type
      # @param [String] path
      # @param [<Resource::Sandbox, Resource::Group>] sandbox
      # @return [<Resource::Sandbox, Resource::Group>]
      def create(type, path:, parent: nil)
        resource_class = type == :sandbox ? Resource::Sandbox : Resource::Group

        resource_class.fabricate_via_api! do |resource|
          resource.api_client = api_client
          resource.sandbox = parent unless type == :sandbox
          resource.path = path
        end
      end

      # Validate project import file exists
      #
      # @return [void]
      def validate_tar_path
        raise("'#{project_tar_path}' path does not exist!") unless File.exist?(project_tar_path)
      end
    end
  end
end
