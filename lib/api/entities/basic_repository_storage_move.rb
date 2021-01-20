# frozen_string_literal: true

module API
  module Entities
    class BasicRepositoryStorageMove < Grape::Entity
      expose :id
      expose :created_at
      expose :human_state_name, as: :state
      expose :source_storage_name
      expose :destination_storage_name
    end
  end
end
