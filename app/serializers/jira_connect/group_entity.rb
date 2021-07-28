# frozen_string_literal: true

class JiraConnect::GroupEntity < Grape::Entity
  expose :name
  expose :avatar_url
  expose :full_name
  expose :description
end
