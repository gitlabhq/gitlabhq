# frozen_string_literal: true

module Gitlab
  class AuthLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'auth'
    end
  end
end

Gitlab::AuthLogger.prepend_mod
