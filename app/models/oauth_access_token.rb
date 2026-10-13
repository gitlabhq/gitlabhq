# frozen_string_literal: true

class OauthAccessToken < Doorkeeper::AccessToken
  include Gitlab::Utils::StrongMemoize
  include Doorkeeper::Concerns::TokenFallback
  include Authz::GranularTokenInterface

  belongs_to :application, class_name: 'Authn::OauthApplication'
  belongs_to :organization, class_name: 'Organizations::Organization'

  validates :expires_in, presence: true

  alias_method :user, :resource_owner
  alias_method :user=, :resource_owner=

  scope :latest_per_application, -> { select('distinct on(application_id) *').order(application_id: :desc, created_at: :desc) }
  scope :preload_application, -> { preload(application: :owner) }

  RETENTION_PERIOD = 1.month

  def scopes=(value)
    if value.is_a?(Array)
      super(Doorkeeper::OAuth::Scopes.from_array(value).to_s)
    else
      super
    end
  end

  def scope_user
    user_id = Authn::ScopedUserExtractor.extract_user_id_from_scopes(scopes)
    return unless user_id

    ::User.find_by_id(user_id)
  end
  strong_memoize_attr :scope_user

  def granular?
    includes_scope?(Gitlab::Auth::GRANULAR_SCOPE)
  end

  def subject_to_granular_enforcement?
    false
  end

  def granular_scopes
    consent_grant ? consent_grant.granular_scopes : Authz::GranularScope.none
  end

  def consent_grant
    Authz::OauthConsentGrant.authorized.not_duo_session.find_by(user_id: resource_owner_id, application_id: application_id)
  end
  strong_memoize_attr :consent_grant
end
