# frozen_string_literal: true

Octokit.middleware.insert_after Octokit::Middleware::FollowRedirects, Gitlab::Octokit::UrlValidation
Octokit.middleware.insert_after Gitlab::Octokit::UrlValidation, Gitlab::Octokit::ResponseValidation
