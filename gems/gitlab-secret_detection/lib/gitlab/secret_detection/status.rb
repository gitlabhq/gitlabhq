# frozen_string_literal: true

module Gitlab
  module SecretDetection
    # All the possible statuses emitted by the scan operation
    class Status
      FOUND = 1 # When scan operation completes with one or more findings
      FOUND_WITH_ERRORS = 2 # When scan operation completes with one or more findings along with some errors
      SCAN_TIMEOUT = 3 # When the scan operation runs beyond given time out
      PAYLOAD_TIMEOUT = 4 # When the scan operation on a payload runs beyond given time out
      SCAN_ERROR = 5 # When the scan operation fails due to regex error
      INPUT_ERROR = 6 # When the scan operation fails due to invalid input
      NOT_FOUND = 7 # When scan operation completes with zero findings
      AUTH_ERROR = 8 # When authentication fails
    end
  end
end
