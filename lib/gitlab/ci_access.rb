# frozen_string_literal: true

module Gitlab
  # For backwards compatibility, generic CI (which is a build without a user) is
  # allowed to :build_download_code without any other checks.
  class CiAccess
    def can_do_action?(action)
      action == :build_download_code
    end
  end
end
