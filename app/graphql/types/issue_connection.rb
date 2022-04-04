# frozen_string_literal: true

# Normally this wouldn't be needed and we could use
#   type Types::IssueType.connection_type, null: true
# in a resolver. However we can end up with cyclic definitions,
# which can result in errors like
#   NameError: uninitialized constant Resolvers::GroupIssuesResolver
#
# Now we would use
#   type "Types::IssueConnection", null: true
# which gives a delayed resolution, and the proper connection type.
# See app/graphql/resolvers/base_issues_resolver.rb
# Reference: https://github.com/rmosolgo/graphql-ruby/issues/3974#issuecomment-1084444214

Types::IssueConnection = Types::IssueType.connection_type
