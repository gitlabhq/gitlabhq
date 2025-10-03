# frozen_string_literal: true

module Integrations
  class ZentaoTrackerData < ApplicationRecord
    include BaseDataFields

    ignore_column :instance_integration_id, remove_with: '18.7', remove_after: '2025-11-20'

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :zentao_product_xid, encryption_options
    attr_encrypted :api_token, encryption_options
  end
end
