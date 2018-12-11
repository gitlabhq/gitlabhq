# frozen_string_literal: true

module QA
  module Resource
    class File < Base
      attr_accessor :name,
                    :content,
                    :commit_message

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

        Page::File::Form.perform do |page|
          page.add_name(@name)
          page.add_content(@content)
          page.add_commit_message(@commit_message)
          page.commit_changes
        end
      end
    end
  end
end
