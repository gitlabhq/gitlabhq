# frozen_string_literal: true

class UserDetail < ApplicationRecord
  include IgnorableColumns
  extend ::Gitlab::Utils::Override

  ignore_column :requires_credit_card_verification, remove_with: '16.1', remove_after: '2023-06-22'

  REGISTRATION_OBJECTIVE_PAIRS = { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5, joining_team: 6 }.freeze

  belongs_to :user

  validates :pronouns, length: { maximum: 50 }
  validates :pronunciation, length: { maximum: 255 }
  validates :job_title, length: { maximum: 200 }
  validates :bio, length: { maximum: 255 }, allow_blank: true

  DEFAULT_FIELD_LENGTH = 500

  # specification for bluesky identifier https://web.plc.directory/spec/v0.1/did-plc
  BLUESKY_VALIDATION_REGEX = /
    \A            # beginning of string
    did:plc:      # beginning of bluesky id
    [a-z0-9]{24}  # 24 characters of word or digit
    \z            # end of string
  /x

  MASTODON_VALIDATION_REGEX = /
    \A            # beginning of string
    @?\b          # optional leading at
    ([\w\d.%+-]+) # character group to pick up words in user portion of username
    @             # separator between user and host
    (             # beginning of character group for host portion
      [\w\d.-]+   # character group to pick up words in host portion of username
      \.\w{2,}    # pick up tld of host domain, 2 chars or more
    )\b           # end of character group to pick up words in host portion of username
    \z            # end of string
  /x

  validates :discord, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validate :discord_format
  validates :linkedin, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :location, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :bluesky,
    allow_blank: true,
    format: { with: UserDetail::BLUESKY_VALIDATION_REGEX,
              message: proc { s_('Profiles|must contain only a bluesky did:plc identifier.') } }
  validates :mastodon, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validate :mastodon_format
  validates :organization, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :skype, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :twitter, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :website_url, length: { maximum: DEFAULT_FIELD_LENGTH }, url: true, allow_blank: true, if: :website_url_changed?
  validates :onboarding_status, json_schema: { filename: 'user_detail_onboarding_status' }

  before_validation :sanitize_attrs
  before_save :prevent_nil_fields

  enum registration_objective: REGISTRATION_OBJECTIVE_PAIRS, _suffix: true

  def sanitize_attrs
    %i[bluesky discord linkedin mastodon skype twitter website_url].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value) if value.present?
    end
    %i[location organization].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value).gsub('&amp;', '&') if value.present?
    end
  end

  private

  def prevent_nil_fields
    self.bluesky = '' if bluesky.nil?
    self.bio = '' if bio.nil?
    self.discord = '' if discord.nil?
    self.linkedin = '' if linkedin.nil?
    self.location = '' if location.nil?
    self.mastodon = '' if mastodon.nil?
    self.organization = '' if organization.nil?
    self.skype = '' if skype.nil?
    self.twitter = '' if twitter.nil?
    self.website_url = '' if website_url.nil?
  end
end

def discord_format
  return if discord.blank? || discord =~ %r{\A\d{17,20}\z}

  errors.add(:discord, _('must contain only a discord user ID.'))
end

def mastodon_format
  return if mastodon.blank? || mastodon =~ UserDetail::MASTODON_VALIDATION_REGEX

  errors.add(:mastodon, _('must contain only a mastodon username.'))
end

UserDetail.prepend_mod_with('UserDetail')
