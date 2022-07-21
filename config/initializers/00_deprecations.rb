# frozen_string_literal: true

# Disallowed deprecation warnings are silenced in production. For performance
# reasons we even skip the definition of disallowed warnings in production.
#
# See
# * https://gitlab.com/gitlab-org/gitlab/-/issues/368379 for a follow-up
# * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92557#note_1032212676
#   for benchmarks
#
# In Rails 7 we will use `config.active_support.report_deprecations = false`
# instead of this early return.
return if Rails.env.production?

# Ban the following deprecation warnings and turn them into runtime errors
# in `development` and `test` environments.
#
# This way we prevent already fixed warnings from sneaking back into the codebase silently.
rails7_deprecation_warnings = [
  # https://gitlab.com/gitlab-org/gitlab/-/issues/339739
  /ActiveModel::Errors#keys is deprecated/,
  # https://gitlab.com/gitlab-org/gitlab/-/issues/342492
  /Rendering actions with '\.' in the name is deprecated/,
  # https://gitlab.com/gitlab-org/gitlab/-/issues/333086
  /default_hash is deprecated/
]

ActiveSupport::Deprecation.disallowed_warnings.concat rails7_deprecation_warnings
