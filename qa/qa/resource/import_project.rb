# frozen_string_literal: true

module QA
  module Resource
    class ImportProject < Resource::Project
      attr_accessor :file_path, :overwrite

      def initialize
        @name = "ImportedProject-#{SecureRandom.hex(8)}"
        @file_path = Runtime::Path.fixture('export.tar.gz')
        @import = true
        @overwrite = false
      end

      def fabricate!
        super

        group.visit!

        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform do |new_project|
          new_project.click_import_project
          new_project.click_gitlab
          new_project.set_imported_project_name(@name)
          new_project.attach_exported_file(@file_path)
          new_project.click_import_gitlab_project
        end
      end

      def api_post_path
        "/projects/import"
      end

      def api_post_body
        {
          file: ::File.new(file_path),
          path: name,
          namespace: personal_namespace || group.full_path,
          overwrite: overwrite
        }
      end

      private

      def transform_api_resource(api_resource)
        api_resource
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end
    end
  end
end
