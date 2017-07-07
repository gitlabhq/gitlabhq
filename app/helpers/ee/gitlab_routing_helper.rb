module EE
  module GitlabRoutingHelper
    include ProjectsHelper
    include ApplicationSettingsHelper

    def geo_primary_web_url(project)
      File.join(::Gitlab::Geo.primary_node.url, ::Gitlab::Routing.url_helpers.project_path(project))
    end

    def geo_primary_ssh_url_to_repo(project)
      "#{::Gitlab::Geo.primary_node.clone_url_prefix}#{project.path_with_namespace}.git"
    end

    def geo_primary_http_url_to_repo(project)
      "#{geo_primary_web_url(project)}.git"
    end

    def geo_primary_default_url_to_repo(project)
      case default_clone_protocol
      when 'ssh'
        geo_primary_ssh_url_to_repo(project)
      else
        geo_primary_http_url_to_repo(project)
      end
    end
  end
end
