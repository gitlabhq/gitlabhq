module EE
  module GitlabRoutingHelper
    def geo_primary_web_url(project)
      File.join(::Gitlab::Geo.primary_node.url, ::Gitlab::Routing.url_helpers.namespace_project_path(project.namespace, project))
    end

    def geo_primary_http_url_to_repo(project)
      "#{geo_primary_web_url(project)}.git"
    end

    def geo_primary_default_url_to_repo(project)
      case default_clone_protocol
      when 'http'
        geo_primary_http_url_to_repo(project)
      end
    end
  end
end
