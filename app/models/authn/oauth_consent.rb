# frozen_string_literal: true

module Authn
  class OauthConsent < ApplicationRecord
    self.table_name = 'oauth_consents'

    belongs_to :user
    belongs_to :application, class_name: 'Authn::OauthApplication',
      foreign_key: :client_id, primary_key: :uid, inverse_of: false

    enum :status, { authorized: 0, revoked: 1 }

    validates :client_id, presence: true
    validates :consent_challenge, presence: true, uniqueness: true
    validate :cannot_update_revoked_consent, on: :update

    private

    def cannot_update_revoked_consent
      errors.add(:status, 'revoked consent cannot be modified') if status_was == 'revoked'
    end
  end
end
