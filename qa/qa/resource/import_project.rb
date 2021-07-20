# frozen_string_literal: true

module QA
  module Resource
    class ImportProject < Resource::Project
      attr_writer :file_path

      def initialize
        @name = "ImportedProject-#{SecureRandom.hex(8)}"
        @file_path = ::File.join('qa', 'fixtures', 'export.tar.gz')
      end

      def fabricate!
        self.import = true
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

      def fabricate_via_api!
        raise NotImplementedError
      end
    end
  end
end
