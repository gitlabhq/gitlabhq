# frozen_string_literal: true

class OauthAccessToken < Doorkeeper::AccessToken
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'

  validates :expires_in, presence: true

  alias_attribute :user, :resource_owner

  scope :latest_per_application, -> { select('distinct on(application_id) *').order(application_id: :desc, created_at: :desc) }
  scope :preload_application, -> { preload(:application) }

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
end
