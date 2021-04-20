# frozen_string_literal: true

require 'securerandom'
require 'active_support/core_ext/object/blank'

module QA
  module Resource
    class MergeRequest < Base
      attr_accessor :approval_rules,
                    :id,
                    :title,
                    :description,
                    :source_branch,
                    :target_branch,
                    :target_new_branch,
                    :assignee,
                    :milestone,
                    :labels,
                    :file_name,
                    :file_content
      attr_writer :no_preparation,
                  :wait_for_merge,
                  :template

      attribute :merge_when_pipeline_succeeds
      attribute :merge_status
      attribute :state

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-merge-request'
        end
      end

      attribute :target do
        Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.branch_name = target_branch
          resource.new_branch = @target_new_branch
          resource.remote_branch = target_branch
        end
      end

      attribute :source do
        Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.branch_name = target_branch
          resource.remote_branch = source_branch
          resource.new_branch = false
          resource.file_name = file_name
          resource.file_content = file_content
        end
      end

      def initialize
        @approval_rules = nil
        @title = 'QA test - merge request'
        @description = 'This is a test merge request'
        @source_branch = "qa-test-feature-#{SecureRandom.hex(8)}"
        @assignee = nil
        @milestone = nil
        @labels = []
        @file_name = "added_file-#{SecureRandom.hex(8)}.txt"
        @file_content = "File Added"
        @target_branch = project.default_branch
        @target_new_branch = true
        @no_preparation = false
        @wait_for_merge = true
      end

      def fabricate!
        populate_target_and_source_if_required

        project.visit!
        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform do |new_page|
          new_page.fill_title(@title)
          new_page.choose_template(@template) if @template
          new_page.fill_description(@description) if @description && !@template
          new_page.choose_milestone(@milestone) if @milestone
          new_page.assign_to_me if @assignee == 'me'
          labels.each do |label|
            new_page.select_label(label)
          end
          new_page.add_approval_rules(approval_rules) if approval_rules

          new_page.create_merge_request
        end
      end

      def fabricate_via_api!
        raise ResourceNotFoundError unless id

        resource_web_url(api_get)
      rescue ResourceNotFoundError
        populate_target_and_source_if_required

        super
      end

      def api_merge_path
        "/projects/#{project.id}/merge_requests/#{id}/merge"
      end

      def api_get_path
        "/projects/#{project.id}/merge_requests/#{id}"
      end

      def api_post_path
        "/projects/#{project.id}/merge_requests"
      end

      def api_post_body
        {
          description: @description,
          source_branch: @source_branch,
          target_branch: @target_branch,
          title: @title
        }
      end

      def merge_via_api!
        Support::Waiter.wait_until(sleep_interval: 1) do
          QA::Runtime::Logger.debug("Waiting until merge request with id '#{id}' can be merged")

          reload!.api_resource[:merge_status] == 'can_be_merged'
        end

        Support::Retrier.retry_on_exception do
          response = put(Runtime::API::Request.new(api_client, api_merge_path).url)

          unless response.code == HTTP_STATUS_OK
            raise ResourceUpdateFailedError, "Could not merge. Request returned (#{response.code}): `#{response}`."
          end

          result = parse_body(response)

          project.wait_for_merge(result[:title]) if @wait_for_merge

          result
        end
      end

      def reload!
        # Refabricate so that we can return a new object with updated attributes
        self.class.fabricate_via_api! do |resource|
          resource.project = project
          resource.id = api_resource[:iid]
        end
      end

      private

      def transform_api_resource(api_resource)
        raise ResourceNotFoundError if api_resource.blank?

        super(api_resource)
      end

      def populate_target_and_source_if_required
        @target_branch ||= project.default_branch

        populate(:target, :source) unless @no_preparation
      end
    end
  end
end
