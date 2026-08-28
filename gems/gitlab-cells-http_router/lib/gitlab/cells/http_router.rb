# frozen_string_literal: true

require_relative "http_router/version"
require_relative "http_router/routes_snapshot"

module Gitlab
  module Cells
    # Ruby-side support for the Cells HTTP Router
    # (https://gitlab.com/gitlab-org/cells/http-router).
    #
    # GitLab is the source of truth for how the router must classify requests,
    # so the artifacts the router consumes are generated here rather than in the
    # router repository, which keeps the two from drifting apart.
    #
    # Anything that needs a booted Rails application stays in the monolith. See
    # `lib/tasks/gitlab/cells/routes.rake` in the GitLab monorepo.
    module HttpRouter
    end
  end
end
