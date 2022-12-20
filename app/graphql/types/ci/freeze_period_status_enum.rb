# frozen_string_literal: true

module Types
  module Ci
    class FreezePeriodStatusEnum < BaseEnum
      graphql_name 'CiFreezePeriodStatus'
      description 'Deploy freeze period status'

      value 'ACTIVE', value: :active, description: 'Freeze period is active.'
      value 'INACTIVE', value: :inactive, description: 'Freeze period is inactive.'
    end
  end
end
