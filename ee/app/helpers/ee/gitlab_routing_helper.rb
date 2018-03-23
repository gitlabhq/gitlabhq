module EE
  module GitlabRoutingHelper
    include ::ProjectsHelper
    include ::ApplicationSettingsHelper

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
  end
end
