# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class SearchExperiments < Grape::Entity # rubocop:disable Search/NamespacedClass -- Not related to search
          expose :experiments, using: ::API::Entities::Ml::Mlflow::Experiment, documentation: { is_array: true }
          expose :next_page_token, documentation: { type: 'String' }
        end
      end
    end
  end
end
