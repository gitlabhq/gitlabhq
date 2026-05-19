# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class SearchRuns < Grape::Entity # rubocop:disable Search/NamespacedClass
          expose :candidates, using: ::API::Entities::Ml::Mlflow::Run, as: :runs, documentation: { is_array: true }
          expose :next_page_token, documentation: { type: 'String' }
        end
      end
    end
  end
end
