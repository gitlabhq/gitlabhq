require 'google/apis/options'

##
# Timeouts on Google::Apis::StorageV1::StorageService (via HttpClient)
#
# This configuration is used with the following cases.
# - When an object storage integration (for lfs, job artifact or upload) is enabled with GCS.
#
# More details in https://github.com/google/google-api-ruby-client/blob/master/MIGRATING.md#timeouts
::Google::Apis::ClientOptions.default.open_timeout_sec = 1200
::Google::Apis::ClientOptions.default.read_timeout_sec = 1200
::Google::Apis::ClientOptions.default.send_timeout_sec = 1200
