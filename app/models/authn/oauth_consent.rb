# frozen_string_literal: true

module Authn
  class OauthConsent < ApplicationRecord
    self.table_name = 'oauth_consents'

    belongs_to :user
    belongs_to :application, class_name: 'Authn::OauthApplication',
      foreign_key: :client_id, primary_key: :uid, inverse_of: false, optional: true

    enum :status, { authorized: 0, rejected: 1, revoked: 2 }

    validates :client_id, presence: true
    validates :consent_challenge, presence: true, uniqueness: true
    validates :granted_scopes, presence: true, unless: :rejected?
    validates :requested_scopes, presence: true
    validate :cannot_update_terminal_consent, on: :update

    private

    def cannot_update_terminal_consent
      return unless status_was.in?(%w[revoked rejected])

      errors.add(:status, "#{status_was} consent cannot be modified")
    end
  end
end
