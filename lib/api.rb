# frozen_string_literal: true

# Shared route requirement constants for the REST API.
#
# These live on the `API` module rather than on the `API::API` class so that
# endpoint files can reference them without triggering the autoload of
# `lib/api/api.rb`. `API::API` mounts every endpoint, so touching it from an
# endpoint's class body pulls in the whole API surface and can raise a
# `NameError` when a previously mounted endpoint reads back a constant from the
# endpoint that is still being loaded.
#
# Always reference these with the leading `::`. Inside `module API`, dropping
# the `::` resolves to the `API::API` class and reintroduces the dependency on
# `lib/api/api.rb`.
module API
  # Matches a single URL path segment (any characters except a forward slash).
  NO_SLASH_URL_PART_REGEX = %r{[^/]+}
  NAMESPACE_OR_PROJECT_REQUIREMENTS = { id: NO_SLASH_URL_PART_REGEX }.freeze
  COMMIT_ENDPOINT_REQUIREMENTS = NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(sha: NO_SLASH_URL_PART_REGEX).freeze
  USER_REQUIREMENTS = { user_id: NO_SLASH_URL_PART_REGEX }.freeze

  # Grape 2.4+ no longer honors route-level `format: false`; this never-matching `:format`
  # requirement re-suppresses the implicit `(.:format)` suffix so a trailing extension or
  # dot stays inside the wildcard/param instead of being parsed off as a response format.
  NO_FORMAT_SUFFIX_REQUIREMENT = { format: /(?!)/ }.freeze
end
