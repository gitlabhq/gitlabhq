module EE
  module GitlabRoutingHelper
    include ::ProjectsHelper
    include ::ApplicationSettingsHelper
    include ::API::Helpers::RelatedResourcesHelpers

    def geo_primary_web_url(project_or_wiki)
      File.join(::Gitlab::Geo.primary_node.url, project_or_wiki.full_path)
    end

    def geo_primary_ssh_url_to_repo(project_or_wiki)
      "#{::Gitlab::Geo.primary_node.clone_url_prefix}#{project_or_wiki.full_path}.git"
    end

    def geo_primary_http_url_to_repo(project_or_wiki)
      geo_primary_web_url(project_or_wiki) + '.git'
    end

    def geo_primary_default_url_to_repo(project_or_wiki)
      case default_clone_protocol
      when 'ssh'
        geo_primary_ssh_url_to_repo(project_or_wiki)
      else
        geo_primary_http_url_to_repo(project_or_wiki)
      end
    end

    def epic_path(entity, *args)
      group_epic_path(entity.group, entity, *args)
    end

    def sast_artifact_url(pipeline)
      raw_project_build_artifacts_url(pipeline.project,
                                      pipeline.sast_artifact,
                                      path: Ci::Build::SAST_FILE)
    end

    def dependency_scanning_artifact_url(pipeline)
      raw_project_build_artifacts_url(pipeline.project,
                                      pipeline.dependency_scanning_artifact,
                                      path: Ci::Build::DEPENDENCY_SCANNING_FILE)
    end

    # sast_container_artifact_url is deprecated and replaced with container_scanning_artifact_url (#5778)
    def sast_container_artifact_url(pipeline)
      raw_project_build_artifacts_url(pipeline.project,
                                      pipeline.sast_container_artifact,
                                      path: Ci::Build::SAST_CONTAINER_FILE)
    end

    def container_scanning_artifact_url(pipeline)
      raw_project_build_artifacts_url(pipeline.project,
                                      pipeline.container_scanning_artifact,
                                      path: Ci::Build::CONTAINER_SCANNING_FILE)
    end

    def dast_artifact_url(pipeline)
      raw_project_build_artifacts_url(pipeline.project,
                                      pipeline.dast_artifact,
                                      path: Ci::Build::DAST_FILE)
    end

    def license_management_artifact_url(pipeline)
      raw_project_build_artifacts_url(pipeline.project,
                                      pipeline.license_management_artifact,
                                      path: Ci::Build::LICENSE_MANAGEMENT_FILE)
    end

    def license_management_api_url(project)
      api_v4_projects_managed_licenses_path(id: project.id)
    end
  end
end
