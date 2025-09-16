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

  # user scope format is: `user:$USER_ID`
  SCOPED_USER_REGEX = /\Auser:(\d+)\z/

  def scopes=(value)
    if value.is_a?(Array)
      super(Doorkeeper::OAuth::Scopes.from_array(value).to_s)
    else
      super
    end
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
