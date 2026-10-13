# frozen_string_literal: true

require "cgi"

module Gitlab
  module Cells
    module HttpRouter
      # Locates the copy of the routing snapshot that the HTTP Router has
      # committed. Shared so that the CI gate and the Danger warning can never
      # end up comparing against different files.
      module RouterSnapshot
        PROJECT = "gitlab-org/cells/http-router"
        PATH = "test/routes/gitlab_routes.json"
        DEFAULT_REF = "main"
        DEFAULT_API_URL = "https://gitlab.com/api/v4"

        def self.url(project: PROJECT, ref: DEFAULT_REF, api_url: DEFAULT_API_URL)
          file = CGI.escape(PATH)
          format("%s/projects/%s/repository/files/%s/raw?ref=%s",
            api_url, CGI.escape(project), file, CGI.escape(ref))
        end

        def self.url_from_env(env = ENV)
          env.fetch("CELLS_ROUTER_SNAPSHOT_URL", nil) || url(
            project: env.fetch("CELLS_ROUTER_PROJECT", PROJECT),
            ref: env.fetch("CELLS_ROUTER_REF", DEFAULT_REF),
            api_url: env.fetch("CI_API_V4_URL", DEFAULT_API_URL)
          )
        end

        def self.job_token(env = ENV)
          token = env.fetch("CI_JOB_TOKEN", nil).to_s
          token unless token.empty?
        end
      end
    end
  end
end
