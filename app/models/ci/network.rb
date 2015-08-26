module Ci
  class Network
    class UnauthorizedError < StandardError; end

    include HTTParty

    API_PREFIX = '/api/v3/'

    def authenticate(api_opts)
      opts = {
        query: api_opts
      }

      endpoint = File.join(url, API_PREFIX, 'user')
      response = self.class.get(endpoint, default_opts.merge(opts))

      build_response(response)
    end

    def projects(api_opts, scope = :owned)
      # Dont load archived projects
      api_opts.merge!(archived: false)

      opts = {
        query: api_opts
      }

      query = if scope == :owned
                'projects/owned.json'
              else
                'projects.json'
              end

      endpoint = File.join(url, API_PREFIX, query)
      response = self.class.get(endpoint, default_opts.merge(opts))

      build_response(response)
    end

    def project(api_opts, project_id)
      opts = {
        query: api_opts
      }

      query = "projects/#{project_id}.json"

      endpoint = File.join(url, API_PREFIX, query)
      response = self.class.get(endpoint, default_opts.merge(opts))

      build_response(response)
    end

    def project_hooks(api_opts, project_id)
      opts = {
        query: api_opts
      }

      query = "projects/#{project_id}/hooks.json"

      endpoint = File.join(url, API_PREFIX, query)
      response = self.class.get(endpoint, default_opts.merge(opts))

      build_response(response)
    end

    def enable_ci(project_id, data, api_opts)
      opts = {
        body: data.to_json,
        query: api_opts
      }

      query = "projects/#{project_id}/services/gitlab-ci.json"
      endpoint = File.join(url, API_PREFIX, query)
      response = self.class.put(endpoint, default_opts.merge(opts))

      case response.code
      when 200
        true
      when 401
        raise UnauthorizedError
      else
        nil
      end
    end

    def disable_ci(project_id, api_opts)
      opts = {
        query: api_opts
      }

      query = "projects/#{project_id}/services/gitlab-ci.json"

      endpoint = File.join(url, API_PREFIX, query)
      response = self.class.delete(endpoint, default_opts.merge(opts))

      build_response(response)
    end

    private

    def url
      GitlabCi.config.gitlab_server.url
    end

    def default_opts
      {
        headers: { "Content-Type" => "application/json" },
      }
    end

    def build_response(response)
      case response.code
      when 200
        response.parsed_response
      when 401
        raise UnauthorizedError
      else
        nil
      end
    end
  end
end
