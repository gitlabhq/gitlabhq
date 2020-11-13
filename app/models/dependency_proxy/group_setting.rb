# frozen_string_literal: true

class DependencyProxy::GroupSetting < ApplicationRecord
  belongs_to :group

  validates :group, presence: true

  default_value_for :enabled, true
end
