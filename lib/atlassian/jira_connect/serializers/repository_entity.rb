# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class RepositoryEntity < BaseEntity
        expose :id, format_with: :string
        expose :name
        expose :description
        expose :url do |project|
          project_url(project)
        end
        expose :avatar do |project|
          project.avatar_url(only_path: false)
        end

        expose :commits do |project, options|
          JiraConnect::Serializers::CommitEntity.represent options[:commits], project: project, update_sequence_id: options[:update_sequence_id]
        end
        expose :branches do |project, options|
          JiraConnect::Serializers::BranchEntity.represent options[:branches], project: project, update_sequence_id: options[:update_sequence_id]
        end
        expose :pullRequests do |project, options|
          JiraConnect::Serializers::PullRequestEntity.represent(
            options[:merge_requests],
            update_sequence_id: options[:update_sequence_id],
            user_notes_count: options[:user_notes_count]
          )
        end
      end
    end
  end
end
