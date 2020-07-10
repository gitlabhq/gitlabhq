# frozen_string_literal: true

module QA
  module Resource
    class GroupMilestone < Base
      attr_writer :start_date, :due_date

      attribute :id
      attribute :title
      attribute :description

      attribute :group do
        Group.fabricate_via_api! do |resource|
          resource.name = 'group-with-milestone'
        end
      end

      def initialize
        @title = "group-milestone-#{SecureRandom.hex(4)}"
        @description = "My awesome group milestone."
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
    end
  end
end
