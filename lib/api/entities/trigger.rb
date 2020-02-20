# frozen_string_literal: true

module API
  module Entities
    class Trigger < Grape::Entity
      include ::API::Helpers::Presentable

      expose :id
      expose :token
      expose :description
      expose :created_at, :updated_at, :last_used
      expose :owner, using: Entities::UserBasic
    end
  end
end
