# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class SearchExperiments < Grape::Entity # rubocop:disable Search/NamespacedClass -- Not related to search
          expose :experiments, with: Experiment
          expose :next_page_token
        end
      end
    end
  end
end
