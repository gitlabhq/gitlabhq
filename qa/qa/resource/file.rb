# frozen_string_literal: true

module QA
  module Resource
    class File < Base
      attr_accessor :author_email,
                    :author_name,
                    :branch,
                    :content,
                    :commit_message,
                    :name

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-new-file'
        end
      end

      def initialize
        @name = 'QA Test - File name'
        @content = 'QA Test - File content'
        @commit_message = 'QA Test - Commit message'
      end

      def fabricate!
        project.visit!

        Page::Project::Show.perform(&:create_first_new_file!)

        Page::File::Form.perform do |form|
          form.add_name(@name)
          form.add_content(@content)
          form.add_commit_message(@commit_message)
          form.commit_changes
        end
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/projects/#{CGI.escape(project.path_with_namespace)}/repository/files/#{CGI.escape(@name)}"
      end

      def api_post_path
        api_get_path
      end

      def api_post_body
        {
          branch: @branch || "master",
          author_email: @author_email || Runtime::User.default_email,
          author_name: @author_name || Runtime::User.username,
          content: content,
          commit_message: commit_message
        }
      end
    end
  end
end
