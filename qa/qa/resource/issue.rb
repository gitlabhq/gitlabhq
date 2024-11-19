# frozen_string_literal: true

module QA
  module Resource
    class Issue < Issuable
      attr_writer :milestone, :template, :weight

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-for-issues'
          resource.description = 'project for adding issues'
          resource.api_client = api_client
        end
      end

      attributes :id,
        :iid,
        :assignee_ids,
        :labels,
        :title,
        :description,
        :state

      attribute :confidential do
        false
      end

      attribute :issue_type do
        'issue'
      end

      def initialize
        @assignee_ids = []
        @labels = []
        @title = "Issue title #{SecureRandom.hex(8)}"
        @description = "Issue description #{SecureRandom.hex(8)}"
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_new_issue)

        Page::Project::Issue::New.perform do |new_page|
          new_page.fill_title(@title)
          new_page.choose_template(@template) if @template
          new_page.fill_description(@description) if @description && !@template
          new_page.choose_milestone(@milestone) if @milestone
          new_page.create_new_issue
        end
      end

      def api_get_path
        "/projects/#{project.id}/issues/#{iid}"
      end

      def api_post_path
        "/projects/#{project.id}/issues"
      end

      def api_put_path
        "/projects/#{project.id}/issues/#{iid}"
      end

      def api_post_body
        {
          assignee_ids: assignee_ids,
          labels: labels,
          title: title,
          confidential: confidential,
          issue_type: issue_type
        }.tap do |hash|
          hash[:milestone_id] = @milestone.id if @milestone
          hash[:weight] = @weight if @weight
          hash[:description] = @description if @description
        end
      end

      def api_related_mrs_path
        "#{api_get_path}/related_merge_requests"
      end

      # Close issue
      #
      # @return [void]
      def close
        api_put_to(api_put_path, state_event: "close")
      end

      def set_issue_assignees(assignee_ids:)
        put_body = { assignee_ids: assignee_ids }
        response = put Runtime::API::Request.new(api_client, api_put_path).url, put_body

        unless response.code == HTTP_STATUS_OK
          raise(
            ResourceUpdateFailedError,
            "Could not update issue assignees to #{assignee_ids}. Request returned (#{response.code}): `#{response}`."
          )
        end

        QA::Runtime::Logger.debug("Successfully updated issue assignees to #{assignee_ids}")
      end

      # Related merge requests
      #
      # @return [Array<Hash>]
      def related_merge_requests
        parse_body(api_get_from(api_related_mrs_path))
      end

      protected

      # Return subset of fields for comparing issues
      #
      # @return [Hash]
      def comparable
        reload! if api_response.nil?

        api_resource.slice(
          :state,
          :description,
          :type,
          :title,
          :labels,
          :milestone,
          :upvotes,
          :downvotes,
          :merge_requests_count,
          :user_notes_count,
          :due_date,
          :has_tasks,
          :task_status,
          :confidential,
          :discussion_locked,
          :issue_type,
          :task_completion_status,
          :closed_at,
          :created_at
        )
      end
    end
  end
end
