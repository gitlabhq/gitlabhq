# frozen_string_literal: true

module API
  module Entities
    class Package < Grape::Entity
      class Pipeline < ::API::Entities::PipelineBasic
        expose :user, using: ::API::Entities::UserBasic
      end
    end
  end
end
