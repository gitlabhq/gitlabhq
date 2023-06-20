# frozen_string_literal: true

module QA
  module Resource
    class GroupMilestone < Base
      attributes :id,
        :iid,
        :title,
        :description,
        :start_date,
        :due_date,
        :updated_at,
        :created_at

      attribute :group do
        Group.fabricate_via_api! do |resource|
          resource.name = "group-with-milestone-#{SecureRandom.hex(4)}"
        end
      end

      def initialize
        @title = "group-milestone-#{SecureRandom.hex(4)}"
        @description = "My awesome group milestone."
      end

      def fabricate!
        group.visit!

        Page::Group::Menu.perform(&:go_to_milestones)
        Page::Group::Milestone::Index.perform(&:click_new_milestone_link)

        Page::Group::Milestone::New.perform do |new_milestone|
          new_milestone.set_title(@title)
          new_milestone.set_description(@description)
          new_milestone.set_start_date(@start_date) if @start_date
          new_milestone.set_due_date(@due_date) if @due_date
          new_milestone.click_create_milestone_button
        end
      end

      def api_get_path
        "/groups/#{group.id}/milestones/#{id}"
      end

      def api_post_path
        "/groups/#{group.id}/milestones"
      end

      def api_post_body
        {
          title: title,
          description: description
        }.tap do |hash|
          hash[:start_date] = @start_date if @start_date
          hash[:due_date] = @due_date if @due_date
        end
      end

      protected

      # Return subset of fields for comparing milestones
      #
      # @return [Hash]
      def comparable
        reload! unless api_response

        api_response.slice(
          :title,
          :description,
          :state,
          :due_date,
          :start_date
        )
      end
    end
  end
end
