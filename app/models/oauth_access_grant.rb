# frozen_string_literal: true

class OauthAccessGrant < Doorkeeper::AccessGrant
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'
end
