# frozen_string_literal: true

class ExperimentUser < ApplicationRecord
  include ::Gitlab::Experimentation::GroupTypes

  belongs_to :experiment
  belongs_to :user

  enum group_type: { GROUP_CONTROL => 0, GROUP_EXPERIMENTAL => 1 }

  validates :experiment_id, presence: true
  validates :user_id, presence: true
  validates :group_type, presence: true
end
