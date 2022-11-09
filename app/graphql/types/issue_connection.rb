# frozen_string_literal: true

# Normally this wouldn't be needed and we could use
#
#   type Types::IssueType.connection_type, null: true
#
# in a resolver. However we can end up with cyclic definitions.
# Running the spec locally can result in errors like
#
#   NameError: uninitialized constant Resolvers::GroupIssuesResolver
#
# or other errors.  To fix this, we created this file and use
#
#   type "Types::IssueConnection", null: true
#
# which gives a delayed resolution, and the proper connection type.
#
# See app/graphql/resolvers/base_issues_resolver.rb
# Reference: https://github.com/rmosolgo/graphql-ruby/issues/3974#issuecomment-1084444214
# and https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#testing-tips-and-tricks
#
Types::IssueConnection = Types::IssueType.connection_type
