# frozen_string_literal: true

require 'google/apis/options'

# these require solve load order issues (undefined constant Google::Apis::ServerError and Signet::RemoteServerError, rescued in multiple places)
require 'google/apis/errors'
require 'signet/errors'

# As stated in https://github.com/googleapis/google-api-ruby-client#errors--retries,
# enabling retries is strongly encouraged but disabled by default. Large uploads
# that may hit timeouts will mainly benefit from this.
Google::Apis::RequestOptions.default.retries = 3 if Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_GOOGLE_API_RETRIES', true))

# By default, httpclient will set a send timeout of 120 seconds (https://github.com/nahi/httpclient/blob/82929c4baae14c2319c3f9aba49488c6f6def875/lib/httpclient/session.rb#L147),
# which causes any request to be interrupted every 2 minutes (https://github.com/nahi/httpclient/blob/82929c4baae14c2319c3f9aba49488c6f6def875/lib/httpclient/session.rb#L515).
#
# The Google API client uses resumable uploads so that if a transfer
# request is interrupted, it can retry where it left off. The client
# will retry at most N + 1 times, which means transfers can only last as
# long as this (N + 1) * send timeout. We raise this timeout to an hour
# since otherwise transfers can only last 8 minutes (4 * 2 min) before
# being interrupted.
Google::Apis::ClientOptions.default.send_timeout_sec = 3600
