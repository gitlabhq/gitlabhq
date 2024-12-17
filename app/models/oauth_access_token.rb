# frozen_string_literal: true

class OauthAccessToken < Doorkeeper::AccessToken
  include Gitlab::Utils::StrongMemoize

  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'
  belongs_to :organization, class_name: 'Organizations::Organization'

  validates :expires_in, presence: true

  alias_attribute :user, :resource_owner

  scope :latest_per_application, -> { select('distinct on(application_id) *').order(application_id: :desc, created_at: :desc) }
  scope :preload_application, -> { preload(:application) }

  # user scope format is: `user:$USER_ID`
  SCOPED_USER_REGEX = /\Auser:(\d+)\z/

  def scopes=(value)
    if value.is_a?(Array)
      super(Doorkeeper::OAuth::Scopes.from_array(value).to_s)
    else
      super
    end
  end

  # this method overrides a shortcoming upstream, more context:
  # https://gitlab.com/gitlab-org/gitlab/-/issues/367888
  def self.find_by_fallback_token(attr, plain_secret)
    return unless fallback_secret_strategy && fallback_secret_strategy == Doorkeeper::SecretStoring::Plain
    # token is hashed, don't allow plaintext comparison
    return if plain_secret.starts_with?("$")

    super
  end

  # Override Doorkeeper::AccessToken.matching_token_for since we
  # have `reuse_access_tokens` disabled and we also hash tokens.
  # This ensures we don't accidentally return a hashed token value.
  def self.matching_token_for(application, resource_owner, scopes)
    # no-op
  end

  def scope_user
    user_id = extract_user_id_from_scopes
    return unless user_id

    ::User.find_by_id(user_id)
  end
  strong_memoize_attr :scope_user

  private

  def extract_user_id_from_scopes
    # scopes are an instance of Doorkeeper:OAuth::Scopes class
    matches = scopes.grep(SCOPED_USER_REGEX)
    return unless matches.length == 1

    matches[0][SCOPED_USER_REGEX, 1].to_i
  end
end
