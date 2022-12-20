# frozen_string_literal: true

class UserDetail < ApplicationRecord
  extend ::Gitlab::Utils::Override

  REGISTRATION_OBJECTIVE_PAIRS = { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5, joining_team: 6 }.freeze

  belongs_to :user

  validates :pronouns, length: { maximum: 50 }
  validates :pronunciation, length: { maximum: 255 }
  validates :job_title, length: { maximum: 200 }
  validates :bio, length: { maximum: 255 }, allow_blank: true

  DEFAULT_FIELD_LENGTH = 500

  validates :linkedin, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :twitter, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :skype, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :location, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :organization, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :website_url, length: { maximum: DEFAULT_FIELD_LENGTH }, url: true, allow_blank: true, if: :website_url_changed?

  before_validation :sanitize_attrs
  before_save :prevent_nil_bio

  enum registration_objective: REGISTRATION_OBJECTIVE_PAIRS, _suffix: true

  def self.user_fields_changed?(user)
    (%w[linkedin skype twitter website_url location organization] & user.changed).any?
  end

  def sanitize_attrs
    %i[linkedin skype twitter website_url].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value) if value.present?
    end
    %i[location organization].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value).gsub('&amp;', '&') if value.present?
    end
  end

  def assign_changed_fields_from_user
    self.linkedin = trim_field(user.linkedin) if user.linkedin_changed?
    self.twitter = trim_field(user.twitter) if user.twitter_changed?
    self.skype = trim_field(user.skype) if user.skype_changed?
    self.website_url = trim_field(user.website_url) if user.website_url_changed?
    self.location = trim_field(user.location) if user.location_changed?
    self.organization = trim_field(user.organization) if user.organization_changed?
  end

  private

  def prevent_nil_bio
    self.bio = '' if bio_changed? && bio.nil?
  end

  def trim_field(value)
    return '' unless value

    value.first(DEFAULT_FIELD_LENGTH)
  end
end

UserDetail.prepend_mod_with('UserDetail')
