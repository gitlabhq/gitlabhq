# frozen_string_literal: true

module Evidences
  class ProjectEntity < Grape::Entity
    expose :id
    expose :name
    expose :description
    expose :created_at
  end
end
