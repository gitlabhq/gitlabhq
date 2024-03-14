# frozen_string_literal: true

module JiraConnect
  class RepositoryEntity < Grape::Entity
    format_with(:iso8601) do |item|
      item.try(:iso8601)
    end

    include Gitlab::Routing

    expose :id
    expose :name
    expose :url do |repository|
      project_url(repository)
    end
    expose :avatar_url, as: :avatarUrl
    expose :updated_at, as: :lastUpdatedDate, format_with: :iso8601
    expose :update_sequence_id, as: :updateSequenceId do |_repository|
      (Time.now.utc.to_f * 1000).round
    end
    expose :namespace, with: WorkspaceEntity, as: :workspace
  end
end
