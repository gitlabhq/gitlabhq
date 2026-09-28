# frozen_string_literal: true

module Authz
  class OauthConsentGrant < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :user, optional: false
    belongs_to :application, class_name: 'Authn::OauthApplication', optional: false

    has_many :oauth_consent_grant_granular_scopes, autosave: true
    has_many :granular_scopes, through: :oauth_consent_grant_granular_scopes

    populate_sharding_key :organization_id, source: :user

    enum :status, { authorized: 0, revoked: 1 }
    enum :source, { doorkeeper: 0, iam_consent: 1, trusted_auto_grant: 2, duo_session: 3 }

    validates :status, :source, presence: true
  end
end
