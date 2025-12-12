# frozen_string_literal: true

class OauthAccessGrant < Doorkeeper::AccessGrant
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Authn::OauthApplication'
  belongs_to :organization, class_name: 'Organizations::Organization'

  RETENTION_PERIOD = 1.month
end
