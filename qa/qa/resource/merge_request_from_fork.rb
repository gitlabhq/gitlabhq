# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class MergeRequestFromFork < MergeRequest
      attr_accessor :fork_branch

      attribute :fork do
        Fork.fabricate!
      end

      attribute :push do
        Repository::ProjectPush.fabricate! do |resource|
          resource.project = fork.project
          resource.branch_name = fork_branch
          resource.file_name = "file2-#{SecureRandom.hex(8)}.txt"
          resource.user = fork.user
        end
      end

      def fabricate!
        populate(:push)

        fork.project.visit!

        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform(&:create_merge_request)
      end
    end
  end
end
