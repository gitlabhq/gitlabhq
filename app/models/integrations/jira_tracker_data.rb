# frozen_string_literal: true

module Integrations
  class JiraTrackerData < ApplicationRecord
    include BaseDataFields

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :username, encryption_options
    attr_encrypted :password, encryption_options

    # These length limits are intended to be generous enough to permit any
    # legitimate usage but provide a sensible upper limit.
    validates :url, length: { maximum: 2048 }, if: :url_changed?
    validates :api_url, length: { maximum: 2048 }, if: :api_url_changed?
    validates :username, length: { maximum: 2048 }, if: :username_changed?
    validates :password, length: { maximum: 2048 }, if: :password_changed?

    enum :deployment_type, { unknown: 0, server: 1, cloud: 2 }, prefix: :deployment
  end
end

Integrations::JiraTrackerData.prepend_mod
