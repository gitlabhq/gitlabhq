# frozen_string_literal: true

class UserDetail < ApplicationRecord
  extend ::Gitlab::Utils::Override
  include IgnorableColumns

  ignore_columns %i[bio_html cached_markdown_version], remove_with: '14.5', remove_after: '2021-10-22'

  REGISTRATION_OBJECTIVE_PAIRS = { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5, joining_team: 6 }.freeze

  belongs_to :user

  validates :pronouns, length: { maximum: 50 }
  validates :pronunciation, length: { maximum: 255 }
  validates :job_title, length: { maximum: 200 }
  validates :bio, length: { maximum: 255 }, allow_blank: true

  before_save :prevent_nil_bio

  enum registration_objective: REGISTRATION_OBJECTIVE_PAIRS, _suffix: true

  private

  def prevent_nil_bio
    self.bio = '' if bio_changed? && bio.nil?
  end
end

UserDetail.prepend_mod_with('UserDetail')
