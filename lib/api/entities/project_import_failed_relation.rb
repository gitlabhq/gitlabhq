# frozen_string_literal: true

module API
  module Entities
    class ProjectImportFailedRelation < Grape::Entity
      expose :id, :created_at, :exception_class, :exception_message, :source

      expose :relation_key, as: :relation_name
    end
  end
end
