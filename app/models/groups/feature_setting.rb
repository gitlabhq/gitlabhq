# frozen_string_literal: true

module Groups
  class FeatureSetting < ApplicationRecord
    self.primary_key = :group_id
    self.table_name = 'group_features'

    belongs_to :group

    validates :group, presence: true
  end
end
