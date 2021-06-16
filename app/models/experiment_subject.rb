# frozen_string_literal: true

class ExperimentSubject < ApplicationRecord
  include ::Gitlab::Experimentation::GroupTypes

  belongs_to :experiment, inverse_of: :experiment_subjects
  belongs_to :user
  belongs_to :namespace
  belongs_to :project

  validates :experiment, presence: true
  validates :variant, presence: true
  validate :must_have_one_subject_present

  enum variant: { GROUP_CONTROL => 0, GROUP_EXPERIMENTAL => 1 }

  def self.valid_subject?(subject)
    subject.is_a?(Namespace) || subject.is_a?(User) || subject.is_a?(Project)
  end

  private

  def must_have_one_subject_present
    if non_nil_subjects.length != 1
      errors.add(:base, s_("ExperimentSubject|Must have exactly one of User, Namespace, or Project."))
    end
  end

  def non_nil_subjects
    @non_nil_subjects ||= [user, namespace, project].reject(&:blank?)
  end
end
