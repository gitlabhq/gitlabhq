# frozen_string_literal: true

module API
  module Entities
    module Dictionary
      class Table < Grape::Entity
        expose :table_name, documentation: { type: :string, example: 'users' }
        expose :feature_categories, documentation: { type: :array, example: ['database'] }
      end
    end
  end
end
