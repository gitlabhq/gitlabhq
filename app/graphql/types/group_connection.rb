# frozen_string_literal: true

# Normally this wouldn't be needed and we could use
#
#   type Types::GroupType.connection_type, null: true
#
# in a resolver. However we can end up with cyclic definitions.
# Running the spec locally can result in errors like
#
#   NameError: uninitialized constant Types::GroupType
#
# or other errors.  To fix this, we created this file and use
#
#   type "Types::GroupConnection", null: true
#
# which gives a delayed resolution, and the proper connection type.
#
# See gitlab/app/graphql/types/ci/runner_type.rb
# Reference: https://github.com/rmosolgo/graphql-ruby/issues/3974#issuecomment-1084444214
# and https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#testing-tips-and-tricks
#
Types::GroupConnection = Types::GroupType.connection_type
