# frozen_string_literal: true

class JiraTrackerData < ApplicationRecord
  include Services::DataFields

  attr_encrypted :url, encryption_options
  attr_encrypted :api_url, encryption_options
  attr_encrypted :username, encryption_options
  attr_encrypted :password, encryption_options
  attr_encrypted :proxy_address, encryption_options
  attr_encrypted :proxy_port, encryption_options
  attr_encrypted :proxy_username, encryption_options
  attr_encrypted :proxy_password, encryption_options

  validates :proxy_address, length: { maximum: 2048 }
  validates :proxy_port, length: { maximum: 5 }
  validates :proxy_username, length: { maximum: 255 }
  validates :proxy_password, length: { maximum: 255 }

  enum deployment_type: { unknown: 0, server: 1, cloud: 2 }, _prefix: :deployment
end
