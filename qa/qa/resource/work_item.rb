# frozen_string_literal: true

module QA
  module Resource
    class WorkItem < Issue
      attribute :work_item_type do
        'Issue'
      end

      def initialize
        super
        @title = "Work item title #{SecureRandom.hex(8)}"
        @description = "Work item description #{SecureRandom.hex(8)}"
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_new_issue)

        Page::Project::WorkItem::New.perform do |new_page|
          new_page.select_type(work_item_type)
          new_page.fill_title(@title)
          new_page.choose_template(@template) if @template
          new_page.fill_description(@description) if @description && !@template
          new_page.choose_milestone(@milestone) if @milestone
          new_page.create_new_work_item
        end
      end

      def api_post_path
        "/projects/#{project.id}/work_items"
      end

      def api_get_path
        "/projects/#{project.id}/work_items/#{iid}"
      end

      def api_put_path
        "/projects/#{project.id}/work_items/#{iid}"
      end

      def api_post_body
        super.merge(work_item_type: work_item_type)
      end

      protected

      # Return subset of fields for comparing work items
      #
      # @return [Hash]
      def comparable
        reload! if api_response.nil?

        api_resource.slice(
          :title
        )
      end
    end
  end
end
