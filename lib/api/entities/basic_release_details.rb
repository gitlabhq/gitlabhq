# frozen_string_literal: true

module API
  module Entities
    class BasicReleaseDetails < Grape::Entity
      include ::API::Helpers::Presentable

      expose :name
      expose :tag, as: :tag_name
      expose :description
      expose :created_at
      expose :released_at
      expose :upcoming_release?, as: :upcoming_release
    end
  end
end
