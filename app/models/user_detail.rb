# frozen_string_literal: true

class UserDetail < ApplicationRecord
  extend ::Gitlab::Utils::Override

  belongs_to :user
  belongs_to :bot_namespace, class_name: 'Namespace', optional: true, inverse_of: :bot_user_details

  validates :pronouns, length: { maximum: 50 }
  validates :pronunciation, length: { maximum: 255 }
  validates :job_title, length: { maximum: 200 }
  validates :bio, length: { maximum: 255 }, allow_blank: true

  validate :bot_namespace_user_type, if: :bot_namespace_id_changed?

  ignore_column :registration_objective, remove_after: '2025-07-17', remove_with: '18.2'
  ignore_column :skype, remove_after: '2025-09-18', remove_with: '18.4'

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

  ORCID_VALIDATION_REGEX = /
    \A            # beginning of string
    (             #
      [0-9]{4}-   # 4 digits spaced by dash
    ){3}          # 3 times
    (             #
    [0-9]{3}      # end with 3 digits
    )             #
    [0-9X]        # followed by a fourth digit or an X
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
  validates :orcid, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validate :orcid_format
  validates :organization, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :twitter, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :website_url, length: { maximum: DEFAULT_FIELD_LENGTH }, url: true, allow_blank: true, if: :website_url_changed?
  validates :onboarding_status, json_schema: { filename: 'user_detail_onboarding_status' }
  validates :github, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true

  before_validation :sanitize_attrs
  before_save :prevent_nil_fields

  def sanitize_attrs
    %i[bluesky discord linkedin mastodon orcid twitter website_url github].each do |attr|
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
    self.orcid = '' if orcid.nil?
    self.twitter = '' if twitter.nil?
    self.website_url = '' if website_url.nil?
    self.github = '' if github.nil?
  end

  def bot_namespace_user_type
    return if user.bot?
    return if bot_namespace_id.nil?

    errors.add(:bot_namespace, _('must only be set for bot user types'))
  end
end

def discord_format
  return if discord.blank? || discord =~ %r{\A\d{17,20}\z}

  errors.add(:discord, _('must contain only a discord user ID.'))
end

def mastodon_format
  return if mastodon.blank? || mastodon =~ UserDetail::MASTODON_VALIDATION_REGEX

  errors.add(:mastodon, _('must contain only a mastodon handle.'))
end

def orcid_format
  return if orcid.blank? || orcid =~ UserDetail::ORCID_VALIDATION_REGEX

  errors.add(:orcid, _('must contain only a valid ORCID.'))
end

UserDetail.prepend_mod_with('UserDetail')
