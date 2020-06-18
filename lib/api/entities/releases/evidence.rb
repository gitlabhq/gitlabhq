# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Evidence < Grape::Entity
        include ::API::Helpers::Presentable

        expose :sha
        expose :filepath
        expose :collected_at
      end
    end
  end
end
