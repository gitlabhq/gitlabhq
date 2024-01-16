# frozen_string_literal: true

module QA
  module Support
    module Helpers
      module Plan
        FREE = { name: 'free', price: 0, yearly_price: 0, compute_minutes: 400 }.freeze

        PREMIUM = {
          plan_id: '2c92a00d76f0d5060176f2fb0a5029ff',
          rate_charge_id: '2c92a00d76f0d5060176f2fb0a672a02',
          name: 'premium',
          price: 19,
          yearly_price: 228,
          compute_minutes: 10000
        }.freeze

        PREMIUM_SELF_MANAGED = {
          plan_id: '2c92a01176f0d50a0176f3043c4d4a53',
          rate_charge_id: '2c92a01176f0d50a0176f3043c6a4a58',
          name: 'premium',
          price: 19,
          yearly_price: 228
        }.freeze

        ULTIMATE = {
          plan_id: '2c92a0ff76f0d5250176f2f8c86f305a',
          rate_charge_id: '2c92a0ff76f0d5250176f2f8c896305c',
          name: 'ultimate',
          price: 99,
          yearly_price: 1188,
          compute_minutes: 50000
        }.freeze

        ULTIMATE_SELF_MANAGED = {
          plan_id: '2c92a00c76f0c6c20176f2f9328b33c9',
          rate_charge_id: '2c92a00c76f0c6c20176f2fcbb645b5f',
          name: 'ultimate',
          price: 99,
          yearly_price: 1188
        }.freeze

        COMPUTE_MINUTES = {
          plan_id: '2c92a0086a07f4a8016a2c0a1f7b4b4c',
          rate_charge_id: '2c92a0fd6a07f4c6016a2c0af07c3f21',
          name: 'compute_minutes',
          price: 10,
          compute_minutes: 1000
        }.freeze

        STORAGE = {
          plan_id: '2c92a00f7279a6f5017279d299d01cf9',
          rate_charge_id: '2c92a0ff7279a74f017279d5bea71fc5',
          name: 'storage',
          price: 60,
          storage: 10
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
