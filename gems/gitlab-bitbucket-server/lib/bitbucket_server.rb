# frozen_string_literal: true

require "active_support/core_ext/hash/keys"
require "active_support/core_ext/module/delegation"
require "active_support/concern"
require "addressable"
require "cgi"
require "gitlab/utils/all"
require "gitlab/http_v2"

require_relative "bitbucket_server/version"

# Representation layer (no external deps beyond activesupport)
require_relative "bitbucket_server/representation/base"
require_relative "bitbucket_server/representation/activity"
require_relative "bitbucket_server/representation/comment"
require_relative "bitbucket_server/representation/pull_request"
require_relative "bitbucket_server/representation/pull_request_comment"
require_relative "bitbucket_server/representation/repo"
require_relative "bitbucket_server/representation/user"

# Pagination layer
require_relative "bitbucket_server/page"
require_relative "bitbucket_server/paginator"
require_relative "bitbucket_server/collection"

# Connection and client
require_relative "bitbucket_server/retry_with_delay"
require_relative "bitbucket_server/connection"
require_relative "bitbucket_server/client"

module BitbucketServer
end
