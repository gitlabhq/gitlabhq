module EE
  module ProjectsHelper
    def can_change_push_rule?(push_rule, rule)
      return true if push_rule.global?

      can?(current_user, :"change_#{rule}", @project)
    end

    def external_classification_label_help_message
      default_label = ::Gitlab::CurrentSettings.current_application_settings
                        .external_authorization_service_default_label

      s_(
        "ExternalAuthorizationService|When no classification label is set the "\
        "default label `%{default_label}` will be used."
      ) % { default_label: default_label }
    end

    def ci_cd_projects_available?
      ::License.feature_available?(:ci_cd_projects) && import_sources_enabled?
    end
  end
end
