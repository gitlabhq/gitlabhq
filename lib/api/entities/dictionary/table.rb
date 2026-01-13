# frozen_string_literal: true

module API
  module Entities
    module Dictionary
      class Table < Grape::Entity
        expose :table_name, documentation: { type: 'String', example: 'users' }
        expose :feature_categories, documentation: { type: 'String', is_array: true, example: 'database' }
      end
    end
  end
end
