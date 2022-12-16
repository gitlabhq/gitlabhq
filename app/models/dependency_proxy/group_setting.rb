# frozen_string_literal: true

class DependencyProxy::GroupSetting < ApplicationRecord
  belongs_to :group

  validates :group, presence: true
end
