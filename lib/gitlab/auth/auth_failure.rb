# frozen_string_literal: true

module Gitlab
  module Auth
    # Value object that groups all authentication-failure metadata written to
    # the Labkit log context.  Using a single struct keeps the five fields
    # atomic: they are always set and cleared as one unit, and there is one
    # canonical place to add or rename a field.
    #
    # Pushed into Gitlab::ApplicationContext as the :auth_fail attribute, which
    # expands it into the individual log fields via AuthFailure::LOG_KEYS when
    # building the lazy hash.
    AuthFailure = Struct.new(
      :reason,
      :token_id,
      :requested_scopes,
      :token_type,
      :auth_header_type,
      keyword_init: true
    )

    # Maps the Labkit/ApplicationContext log-key name to the corresponding
    # AuthFailure attribute.  Defined as AuthFailure::LOG_KEYS (rather than a
    # plain module-level constant) so that referencing it as
    # Gitlab::Auth::AuthFailure::LOG_KEYS causes Zeitwerk to autoload this file
    # by resolving the AuthFailure class first.
    AuthFailure::LOG_KEYS = {
      auth_fail_reason: :reason,
      auth_fail_token_id: :token_id,
      auth_fail_requested_scopes: :requested_scopes,
      auth_fail_token_type: :token_type,
      auth_fail_auth_header_type: :auth_header_type
    }.freeze
  end
end
