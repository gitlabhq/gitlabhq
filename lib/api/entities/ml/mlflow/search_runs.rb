# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class SearchRuns < Grape::Entity # rubocop:disable Search/NamespacedClass
          expose :candidates, with: Run, as: :runs
          expose :next_page_token
        end
      end
    end
  end
end
