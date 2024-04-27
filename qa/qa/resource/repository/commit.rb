# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class Commit < Base
        attr_accessor :branch, :commit_message, :file_path, :sha, :start_branch, :actions

        attribute :short_id

        attribute :project do
          Project.fabricate! do |resource|
            resource.name = 'project-with-commit'
          end
        end

        def initialize
          @commit_message = 'QA Test - Commit message'
          @actions = []
        end

        # If `actions` are specified, it performs the actions to create,
        # update, or delete commits. If no actions are specified it
        # gets existing commits.
        def fabricate_via_api!
          return api_get if actions.empty?

          super
        rescue ResourceNotFoundError
          result = super

          project.wait_for_push(commit_message)

          result
        end

        def api_get_path
          "/projects/#{CGI.escape(project.path_with_namespace)}/repository/commits"
        end

        def api_post_path
          api_get_path
        end

        def api_post_body
          {
            branch: branch || project.default_branch,
            commit_message: commit_message,
            actions: actions
          }.merge(new_branch)
        end

        # Add files
        # Pass in array of new files like, example:
        # [{ "file_path": "foo/bar", "content": "some content" }]
        #
        # @param [Array<Hash>] files
        # @return [void]
        def add_files(files)
          validate_files!(files)

          actions.push(*files.map { |file| file.merge({ action: "create" }) })
        end

        # Update files
        # Pass in array of files and it's contents, example:
        # [{ "file_path": "foo/bar", "content": "some content" }]
        #
        # @param [Array<Hash>] files
        # @return [void]
        def update_files(files)
          validate_files!(files)

          actions.push(*files.map { |file| file.merge({ action: "update" }) })
        end

        # Add all files from directory
        #
        # @param [Pathname] dir
        # @return [void]
        def add_directory(dir)
          raise "Must set directory as a Pathname" unless dir.is_a?(Pathname)

          files_to_add = []

          dir.each_child do |child|
            case child.ftype
            when "directory"
              add_directory(child)
            when "file"
              files_to_add.push({ file_path: child.basename, content: child.read })
            else
              continue
            end
          end

          add_files(files_to_add)
        end

        private

        def validate_files!(files)
          if !files.is_a?(Array) ||
              files.empty? ||
              files.any? { |file| !file.has_key?(:file_path) || !file.has_key?(:content) }
            raise ArgumentError, "Please provide an array of hashes e.g.: [{file_path: 'file1', content: 'foo'}]"
          end
        end

        def new_branch
          return {} unless start_branch

          {
            start_branch: start_branch
          }
        end
      end
    end
  end
end
