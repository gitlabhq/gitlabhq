# frozen_string_literal: true

module Authz
  class OauthConsentGrantGranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :oauth_consent_grant, optional: false
    belongs_to :granular_scope, optional: false, autosave: true

    populate_sharding_key :organization_id, source: :oauth_consent_grant
  end
end
