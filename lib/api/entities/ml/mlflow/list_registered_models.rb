# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class ListRegisteredModels < Grape::Entity
          expose :registered_models, using: ::API::Entities::Ml::Mlflow::RegisteredModel, as: :registered_models, documentation: { is_array: true }
          expose :next_page_token, documentation: { type: 'String' }
        end
      end
    end
  end
end
