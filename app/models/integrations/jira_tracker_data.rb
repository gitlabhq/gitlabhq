# frozen_string_literal: true

module Integrations
  class JiraTrackerData < ApplicationRecord
    include BaseDataFields

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :username, encryption_options
    attr_encrypted :password, encryption_options

    enum deployment_type: { unknown: 0, server: 1, cloud: 2 }, _prefix: :deployment
  end
end
