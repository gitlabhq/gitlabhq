# frozen_string_literal: true

class OpenProjectTrackerData < ApplicationRecord
  include Services::DataFields

  # When the Open Project is fresh installed, the default closed status id is "13" based on current version: v8.
  DEFAULT_CLOSED_STATUS_ID = "13"

  attr_encrypted :url, encryption_options
  attr_encrypted :api_url, encryption_options
  attr_encrypted :token, encryption_options

  def closed_status_id
    super || DEFAULT_CLOSED_STATUS_ID
  end
end
