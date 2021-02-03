# frozen_string_literal: true

Octokit.middleware.insert_after Octokit::Middleware::FollowRedirects, Gitlab::Octokit::Middleware
