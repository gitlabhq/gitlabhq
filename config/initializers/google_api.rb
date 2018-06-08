require 'google/apis/options'

##
# Timeouts configuration for Google::Apis::StorageV1::StorageService
#
# This configuration is honored at the following conditions
# - Object storage integrations (LFS/Job Artifact/Upload) is active, and it connects to GCS
#
# More details in https://github.com/google/google-api-ruby-client/blob/master/MIGRATING.md#timeouts
::Google::Apis::ClientOptions.default.open_timeout_sec = 1234 # TODO: Parameter
::Google::Apis::ClientOptions.default.read_timeout_sec = 1234 # TODO: Parameter
::Google::Apis::ClientOptions.default.send_timeout_sec = 1234 # TODO: Parameter
