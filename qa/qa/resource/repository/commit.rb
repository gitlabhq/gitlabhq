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

        attribute :project do
          Project.fabricate! do |resource|
            resource.name = 'project-with-commit'
          end
        end

        def initialize
          @commit_message = 'QA Test - Commit message'
        end

        def files=(files)
          if !files.is_a?(Array) ||
              files.empty? ||
              files.any? { |file| !file.has_key?(:file_path) || !file.has_key?(:content) }
            raise ArgumentError, "Please provide an array of hashes e.g.: [{file_path: 'file1', content: 'foo'}]"
          end

          @files = files
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "#{api_post_path}/#{@sha}"
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
          @files.map do |file|
            file.merge({ action: "create" })
          end
        end
      end
    end
  end
end
