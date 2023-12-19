# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class ListRegisteredModels < Grape::Entity
          expose :registered_models, with: RegisteredModel, as: :registered_models
          expose :next_page_token
        end
      end
    end
  end
end
