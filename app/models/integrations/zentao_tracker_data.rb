# frozen_string_literal: true

module Integrations
  class ZentaoTrackerData < ApplicationRecord
    include BaseDataFields

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :zentao_product_xid, encryption_options
    attr_encrypted :api_token, encryption_options

    # These length limits are intended to be generous enough to permit any
    # legitimate usage but provide a sensible upper limit.
    validates :url, length: { maximum: 2048 }, if: :url_changed?
    validates :api_url, length: { maximum: 2048 }, if: :api_url_changed?
    validates :zentao_product_xid, length: { maximum: 255 }, if: :zentao_product_xid_changed?
    validates :api_token, length: { maximum: 255 }, if: :api_token_changed?
  end
end
