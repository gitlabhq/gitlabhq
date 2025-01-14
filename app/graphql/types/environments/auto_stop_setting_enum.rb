# frozen_string_literal: true

module Types
  module Environments
    class AutoStopSettingEnum < BaseEnum
      graphql_name 'AutoStopSetting'
      description 'Auto stop setting.'

      ::Environment.auto_stop_settings.each_key do |key|
        value key.upcase, value: key, description: key.titleize
      end
    end
  end
end
