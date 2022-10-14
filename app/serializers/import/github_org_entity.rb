# frozen_string_literal: true

module Import
  class GithubOrgEntity < Grape::Entity
    expose :login, as: :name
    expose :description
  end
end
