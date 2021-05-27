# frozen_string_literal: true

module Integrations
  class OpenProjectTrackerData < ApplicationRecord
    include BaseDataFields

    # When the Open Project is fresh installed, the default closed status id is "13" based on current version: v8.
    DEFAULT_CLOSED_STATUS_ID = "13"

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :token, encryption_options

    def closed_status_id
      super || DEFAULT_CLOSED_STATUS_ID
    end
  end
end
