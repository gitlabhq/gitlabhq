# frozen_string_literal: true

module QA
  module Resource
    class File < Base
      attr_accessor :content, :commit_message, :name, :start_branch
      attr_writer :branch

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-new-file'

          # Creating the first file via the Wed IDE is tested in
          # browser_ui/3_create/web_ide/create_first_file_in_web_ide_spec.rb
          # So here we want to use the old blob viewer, which is not
          # available via the UI unless at least one file exists, which
          # is why we create the project with a readme file.
          resource.initialize_with_readme = true
        end
      end

      def initialize
        @name = 'QA Test - File name'
        @content = 'QA Test - File content'
        @commit_message = 'QA Test - Commit message'
        @start_branch = project.default_branch
      end

      def branch
        @branch ||= project.default_branch
      end

      def fabricate!
        project.visit!

        Page::Project::Show.perform(&:create_new_file!)

        Page::File::Form.perform do |form|
          form.add_name(@name)
          form.add_content(@content)
          form.click_commit_changes_in_header
          form.add_commit_message(@commit_message)
          form.commit_changes_through_modal
        end
      end

      def api_get_path
        "/projects/#{CGI.escape(project.path_with_namespace)}/repository/files/#{CGI.escape(@name)}"
      end

      def api_post_path
        api_get_path
      end

      def api_post_body
        {
          branch: branch,
          start_branch: start_branch,
          content: content,
          commit_message: commit_message
        }
      end

      private

      def transform_api_resource(api_resource)
        api_resource[:web_url] = "#{Runtime::Scenario.gitlab_address}/#{project.full_path}/-/blob/#{branch}/#{api_resource[:file_path]}"
        api_resource
      end
    end
  end
end
