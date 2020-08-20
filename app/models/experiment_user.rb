# frozen_string_literal: true

class ExperimentUser < ApplicationRecord
  belongs_to :experiment
  belongs_to :user

  enum group_type: { control: 0, experimental: 1 }

  validates :group_type, presence: true
end
