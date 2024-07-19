# frozen_string_literal: true

require 'google/apis/options'

# these require solve load order issues (undefined constant Google::Apis::ServerError and Signet::RemoteServerError, rescued in multiple places)
require 'google/apis/errors'
require 'signet/errors'

# As stated in https://github.com/googleapis/google-api-ruby-client#errors--retries,
# enabling retries is strongly encouraged but disabled by default. Large uploads
# that may hit timeouts will mainly benefit from this.
Google::Apis::RequestOptions.default.retries = 3 if Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_GOOGLE_API_RETRIES', true))

# The default chunk size of 100MB provides no performance benefits
# while using more memory at peak, see discussion in
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108456#note_1259008557
Google::Apis::RequestOptions.default.upload_chunk_size = 10.megabytes

logger = Gitlab::AppJsonLogger.build

logger.level = Logger::INFO

Google::Apis.logger = logger
