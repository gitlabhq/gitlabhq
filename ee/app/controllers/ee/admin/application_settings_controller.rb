module EE
  module Admin
    module ApplicationSettingsController
      def visible_application_setting_attributes
        attrs = super

        if License.feature_available?(:repository_mirrors)
          attrs += EE::ApplicationSettingsHelper.repository_mirror_attributes
        end

        attrs
      end
    end
  end
end
