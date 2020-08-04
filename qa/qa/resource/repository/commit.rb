# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class Commit < Base
        attr_accessor :author_email,
                      :author_name,
                      :branch,
                      :commit_message,
                      :file_path,
                      :sha

        attribute :short_id

        attribute :project do
          Project.fabricate! do |resource|
            resource.name = 'project-with-commit'
          end
        end

        def initialize
          @commit_message = 'QA Test - Commit message'
        end

        def add_files(files)
          validate_files!(files)

          @add_files = files
        end

        def add_directory(dir)
          raise "Must set directory as a Pathname" unless dir.is_a?(Pathname)

          files_to_add = []

          dir.each_child do |child|
            case child.ftype?
            when "file"
              files_to_add.append({
                file_path: child.to_s,
                content: child.read
              })
            when "directory"
              add_directory(child)
            else
              continue
            end
          end

          validate_files!(files_to_add)

          @add_files.merge(files_to_add)
        end

        def update_files(files)
          validate_files!(files)

          @update_files = files
        end

        # If `actions` are specified, it performs the actions to create,
        # update, or delete commits. If no actions are specified it
        # gets existing commits.
        def fabricate_via_api!
          return api_get if actions.empty?

          super
        rescue ResourceNotFoundError
          super
        end

        def api_get_path
          api_post_path
        end

        def api_post_path
          "/projects/#{CGI.escape(project.path_with_namespace)}/repository/commits"
        end

        def api_post_body
          {
            branch: @branch || "master",
            author_email: @author_email || Runtime::User.default_email,
            author_name: @author_name || Runtime::User.username,
            commit_message: commit_message,
            actions: actions
          }
        end

        def actions
          pending_actions = []
          pending_actions << @add_files.map { |file| file.merge({ action: "create" }) } if @add_files
          pending_actions << @update_files.map { |file| file.merge({ action: "update" }) } if @update_files
          pending_actions.flatten
        end

        private

        def validate_files!(files)
          if !files.is_a?(Array) ||
              files.empty? ||
              files.any? { |file| !file.has_key?(:file_path) || !file.has_key?(:content) }
            raise ArgumentError, "Please provide an array of hashes e.g.: [{file_path: 'file1', content: 'foo'}]"
          end
        end
      end
    end
  end
end
