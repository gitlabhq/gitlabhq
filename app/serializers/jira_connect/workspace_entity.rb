# frozen_string_literal: true

module JiraConnect
  class WorkspaceEntity < Grape::Entity
    expose :id
    expose :name
    expose :avatar_url, as: :avatarUrl
  end
end
