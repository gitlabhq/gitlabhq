# frozen_string_literal: true

module Ci
  class DestroySecureFileService < BaseService
    def execute(secure_file)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_secure_files, secure_file.project)

      secure_file.destroy!
    end
  end
end
