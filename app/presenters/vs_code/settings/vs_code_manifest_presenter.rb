# frozen_string_literal: true

module VsCode
  module Settings
    class VsCodeManifestPresenter < Gitlab::View::Presenter::Simple
      attr_reader :settings

      def initialize(settings)
        @settings = settings
      end

      def latest
        latest_settings_map = {}
        # There is a default machine stored
        latest_settings_map['machines'] = DEFAULT_MACHINE[:uuid]

        return latest_settings_map if settings.empty?

        persisted_settings = settings.each_with_object({}) do |setting, hash|
          hash[setting.setting_type] = setting.uuid
        end

        latest_settings_map.merge(persisted_settings)
      end

      def session
        DEFAULT_SESSION
      end
    end
  end
end
