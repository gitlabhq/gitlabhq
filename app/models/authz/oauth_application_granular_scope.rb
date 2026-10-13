# frozen_string_literal: true

module Authz
  class OauthApplicationGranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :application, class_name: 'Authn::OauthApplication', optional: false
    belongs_to :granular_scope, optional: false, autosave: true

    populate_sharding_key :organization_id, source: :application
  end
end
