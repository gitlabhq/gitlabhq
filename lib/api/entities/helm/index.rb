# frozen_string_literal: true

module API
  module Entities
    module Helm
      class Index < Grape::Entity
        expose :api_version, as: :apiVersion
        expose :entries
        expose :generated
        expose :server_info, as: :serverInfo
      end
    end
  end
end
