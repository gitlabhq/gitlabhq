# frozen_string_literal: true

class JiraTrackerData < ApplicationRecord
  include Services::DataFields
  include IgnorableColumns

  ignore_columns %i[
    encrypted_proxy_address
    encrypted_proxy_address_iv
    encrypted_proxy_port
    encrypted_proxy_port_iv
    encrypted_proxy_username
    encrypted_proxy_username_iv
    encrypted_proxy_password
    encrypted_proxy_password_iv
  ], remove_with: '14.0', remove_after: '2021-05-22'

  attr_encrypted :url, encryption_options
  attr_encrypted :api_url, encryption_options
  attr_encrypted :username, encryption_options
  attr_encrypted :password, encryption_options

  enum deployment_type: { unknown: 0, server: 1, cloud: 2 }, _prefix: :deployment
end
