# frozen_string_literal: true

class OauthAccessToken < Doorkeeper::AccessToken
  include Gitlab::Utils::StrongMemoize

  belongs_to :application, class_name: 'Doorkeeper::Application'
  belongs_to :organization, class_name: 'Organizations::Organization'

  validates :expires_in, presence: true

  alias_method :user, :resource_owner
  alias_method :user=, :resource_owner=

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

  # Allow looking up previously plain tokens as a fallback
  # IFF a fallback strategy has been defined
  #
  # This method overrides the upstream Doorkeeper implementation to support
  # multiple fallback strategies instead of a single fallback_secret_strategy.
  #
  # @param attr [Symbol] The token attribute we're looking with
  # @param plain_secret [#to_s] Plain secret value (any object that responds to `#to_s`)
  # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil if there is no record with such token
  #
  # @example
  #   OauthAccessToken.find_by_fallback_token(:token, "my_plain_token")
  #   #=> #<OauthAccessToken:0x...> or nil
  #
  # @note This method skips lookup for already hashed tokens to avoid unnecessary processing:
  #   - PBKDF2 hashed tokens (format: $pbkdf2-sha512$20000$$.c0G5XJV...)
  #   - SHA512 hashed tokens (128 hexadecimal characters)
  #
  # @see #upgrade_fallback_value
  # @see .fallback_strategies
  def self.find_by_fallback_token(attr, plain_secret)
    return if plain_secret.start_with?('$pbkdf2-') || # PBKDF2 format
      (plain_secret.length == 128 && plain_secret.match?(/\A[a-f0-9]{128}\z/i)) # SHA512 format

    # Try each fallback strategy until we find a match
    fallback_strategies.each do |fallback_strategy|
      stored_token = fallback_strategy.transform_secret(plain_secret)

      resource = find_by(attr => stored_token)
      if resource
        upgrade_fallback_value(resource, attr, plain_secret)
        return resource
      end
    end
    nil
  end

  private

  def extract_user_id_from_scopes
    # scopes are an instance of Doorkeeper:OAuth::Scopes class
    matches = scopes.grep(SCOPED_USER_REGEX)
    return unless matches.length == 1

    matches[0][SCOPED_USER_REGEX, 1].to_i
  end

  def self.fallback_strategies
    [Gitlab::DoorkeeperSecretStoring::Token::Pbkdf2Sha512, Doorkeeper::SecretStoring::Plain]
  end
end
