# frozen_string_literal: true
module Ci
  module SecureFilesHelper
    def show_secure_files_setting(project, user)
      return false if user.nil?

      user.can?(:read_secure_files, project)
    end
  end
end
