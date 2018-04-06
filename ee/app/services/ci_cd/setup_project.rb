module CiCd
  class SetupProject < ::BaseService
    def execute
      return if project.import_url.blank?

      update_project
      disable_project_features
      setup_external_service
    end

    private

    def update_project
      project.update_attributes(
        mirror:                              true,
        mirror_trigger_builds:               true,
        mirror_overwrites_diverged_branches: true,
        only_mirror_protected_branches:      false,
        mirror_user_id:                      current_user.id
      )
    end

    def disable_project_features
      project.project_feature.update_attributes(
        issues_access_level:         ProjectFeature::DISABLED,
        merge_requests_access_level: ProjectFeature::DISABLED,
        wiki_access_level:           ProjectFeature::DISABLED,
        snippets_access_level:       ProjectFeature::DISABLED
      )
    end

    def setup_external_service
      return unless requires_extra_setup?

      service_class.new(@project).execute
    end

    def requires_extra_setup?
      return false if project.import_type.blank?

      Gitlab::ImportSources.importer(project.import_type).try(:requires_ci_cd_setup?)
    end

    def service_class
      "CiCd::#{@project.import_type.classify}SetupService".constantize
    end
  end
end
