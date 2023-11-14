# frozen_string_literal: true

require "etc"

module QA
  module Tools
    # Helper to generate group with projects for Direct Transfer testing
    #
    # Should be used with care as it can trigger a lot of project imports
    #
    class GenerateImportTestGroup
      # Generate test group
      #
      # @param [String] project_tar_paths exported project tar.gz file path, optionally several separated by ';'
      # @param [String] group_path path of group where projects will be generated
      # @param [Integer] project_copies number of projects to create in a group
      def initialize(
        project_tar_paths: Runtime::Path.fixture('export.tar.gz'),
        group_path: "import-test",
        project_copies: 10
      )
        @project_tar_paths = project_tar_paths
        @group_path = group_path
        @project_copies = project_copies
        @logger = Runtime::Logger.logger
      end

      # Generate group with projects
      #
      # @return [void]
      def generate
        check_access_token
        raise("Project pool has no valid archive files") if project_pool.empty?

        logger.info("Creating '#{group_path}' group with #{project_copies} copies of exported projects")
        create_group

        (1..project_copies).each do
          name = "imported-project-#{SecureRandom.hex(8)}"
          tar = project_pool[rand(0..project_pool.size - 1)]

          logger.info("Fabricating copy of '#{tar.basename}' with name '#{name}'")
          Resource::ImportProject.fabricate_via_api! do |project|
            project.file_path = tar.to_s
            project.api_client = api_client
            project.name = name
            project.group = group
            # we mark project as not import so it doesn't wait for import to finish
            # when generating large projects, it can take a long time
            project.import = false
          end

          sleep(10) # add pause to not trigger 'too many requests error'
        rescue StandardError => e
          logger.error("Failed to fabricate project '#{name}', error: #{e}")
        end
      end

      private

      attr_reader :project_tar_paths, :group_path, :project_copies, :logger

      # Gitlab access token
      #
      # @return [String]
      def access_token
        @access_token ||= ENV['GITLAB_QA_ACCESS_TOKEN'] || raise("GITLAB_QA_ACCESS_TOKEN required")
      end
      alias_method :check_access_token, :access_token

      # API client
      #
      # @return [Runtime::API::Client]
      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab, personal_access_token: access_token)
      end

      # Pool of project tar files
      #
      # @return [Array<Pathname>]
      def project_pool
        @project_pool ||= project_tar_paths.split(";").filter_map do |f|
          path = Pathname.new(f)
          next logger.warn("#{f} is not a valid path!") && nil unless path.exist?

          path
        end
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
    end
  end
end
