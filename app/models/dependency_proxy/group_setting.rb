# frozen_string_literal: true

class DependencyProxy::GroupSetting < ApplicationRecord
  belongs_to :group

  attribute :enabled, default: true

  validates :group, presence: true
end
