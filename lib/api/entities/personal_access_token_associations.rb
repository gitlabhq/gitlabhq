# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenAssociations < Grape::Entity
      expose :groups, using: Entities::GroupAssociationDetails, documentation: { is_array: true }
      expose :projects, using: Entities::ProjectAssociationDetails, documentation: { is_array: true }
    end
  end
end
