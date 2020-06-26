# frozen_string_literal: true

module QA
  module Resource
    class GroupMilestone < Base
      attr_writer :start_date, :due_date

      attribute :id
      attribute :title

      attribute :group do
        Group.fabricate_via_api! do |resource|
          resource.name = 'group-with-milestone'
        end
      end

      def initialize
        @title = "group-milestone-#{SecureRandom.hex(4)}"
      end

      def api_get_path
        "/groups/#{group.id}/milestones/#{id}"
      end

      def api_post_path
        "/groups/#{group.id}/milestones"
      end

      def api_post_body
        {
          title: title
        }.tap do |hash|
          hash[:start_date] = @start_date if @start_date
          hash[:due_date] = @due_date if @due_date
        end
      end
    end
  end
end
