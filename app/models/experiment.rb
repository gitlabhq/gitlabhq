# frozen_string_literal: true

class Experiment < ApplicationRecord
  include ::Gitlab::Experimentation::GroupTypes

  has_many :experiment_users
  has_many :users, through: :experiment_users
  has_many :control_group_users, -> { merge(ExperimentUser.control) }, through: :experiment_users, source: :user
  has_many :experimental_group_users, -> { merge(ExperimentUser.experimental) }, through: :experiment_users, source: :user

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

  def self.add_user(name, group_type, user)
    experiment = find_or_create_by(name: name)

    return unless experiment
    return if experiment.experiment_users.where(user: user).exists?

    group_type == GROUP_CONTROL ? experiment.add_control_user(user) : experiment.add_experimental_user(user)
  end

  def add_control_user(user)
    control_group_users << user
  end

  def add_experimental_user(user)
    experimental_group_users << user
  end
end
