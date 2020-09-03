# frozen_string_literal: true

module Operations
  module FeatureFlags
    class Scope < ApplicationRecord
      prepend HasEnvironmentScope

      self.table_name = 'operations_scopes'

      belongs_to :strategy, class_name: 'Operations::FeatureFlags::Strategy'
    end
  end
end
