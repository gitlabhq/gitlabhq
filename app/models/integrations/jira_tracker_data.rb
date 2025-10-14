# frozen_string_literal: true

module Integrations
  class JiraTrackerData < ApplicationRecord
    include BaseDataFields

    ignore_column :instance_integration_id, remove_with: '18.7', remove_after: '2025-11-20'

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :username, encryption_options
    attr_encrypted :password, encryption_options

    enum :deployment_type, { unknown: 0, server: 1, cloud: 2 }, prefix: :deployment
  end
end

Integrations::JiraTrackerData.prepend_mod
