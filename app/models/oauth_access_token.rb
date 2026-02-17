# frozen_string_literal: true

class OauthAccessToken < Doorkeeper::AccessToken
  include Gitlab::Utils::StrongMemoize
  include Doorkeeper::Concerns::TokenFallback

  belongs_to :application, class_name: 'Authn::OauthApplication'
  belongs_to :organization, class_name: 'Organizations::Organization'

  validates :expires_in, presence: true

  alias_method :user, :resource_owner
  alias_method :user=, :resource_owner=

  scope :latest_per_application, -> { select('distinct on(application_id) *').order(application_id: :desc, created_at: :desc) }
  scope :preload_application, -> { preload(:application) }

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
end
