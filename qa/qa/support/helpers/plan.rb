# frozen_string_literal: true

module QA
  module Support
    module Helpers
      module Plan
        FREE = { name: 'free', price: 0, yearly_price: 0, compute_minutes: 400 }.freeze

        PREMIUM_SELF_MANAGED = {
          plan_id: '2c92a01176f0d50a0176f3043c4d4a53',
          rate_charge_id: '2c92a01176f0d50a0176f3043c6a4a58',
          name: 'premium',
          price: 19,
          yearly_price: 228
        }.freeze

        ULTIMATE_SELF_MANAGED = {
          plan_id: '2c92a00c76f0c6c20176f2f9328b33c9',
          rate_charge_id: '2c92a00c76f0c6c20176f2fcbb645b5f',
          name: 'ultimate',
          price: 99,
          yearly_price: 1188
        }.freeze

        LICENSE_TYPE = {
          legacy_license: 'legacy license',
          online_cloud: 'online license',
          offline_cloud: 'offline license'
        }.freeze
      end
    end
  end
end
