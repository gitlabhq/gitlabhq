module EE
  module Admin
    module ApplicationSettingsController
      def visible_application_setting_attributes
        attrs = super

        if License.feature_available?(:repository_mirrors)
          attrs += EE::ApplicationSettingsHelper.repository_mirror_attributes
        end

        if License.feature_available?(:project_creation_level)
          attrs << :default_project_creation
        end

        if License.feature_available?(:external_authorization_service)
          attrs += EE::ApplicationSettingsHelper.external_authorization_service_attributes
        end

        if License.feature_available?(:custom_project_templates)
          attrs << :custom_project_templates_group_id
        end

        if License.feature_available?(:email_additional_text)
          attrs << :email_additional_text
        end

        if License.feature_available?(:pseudonymizer)
          attrs << :pseudonymizer_enabled
        end

        attrs
      end
    end
  end
end
