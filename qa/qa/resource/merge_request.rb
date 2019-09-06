# frozen_string_literal: true

require 'securerandom'

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

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-merge-request'
        end
      end

      attribute :target do
        project.visit!

        Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.branch_name = 'master'
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
        @target_branch = "master"
        @assignee = nil
        @milestone = nil
        @labels = []
        @file_name = "added_file.txt"
        @file_content = "File Added"
        @target_new_branch = true
      end

      def fabricate!
        populate(:target, :source)

        project.visit!
        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform do |new|
          new.fill_title(@title)
          new.fill_description(@description)
          new.choose_milestone(@milestone) if @milestone
          new.assign_to_me if @assignee == 'me'
          labels.each do |label|
            new.select_label(label)
          end
          new.add_approval_rules(approval_rules) if approval_rules

          new.create_merge_request
        end
      end

      def fabricate_via_api!
        populate(:target, :source)
        super
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
    end
  end
end
