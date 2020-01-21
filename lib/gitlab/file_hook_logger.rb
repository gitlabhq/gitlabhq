# frozen_string_literal: true

module Gitlab
  class FileHookLogger < Gitlab::Logger
    def self.file_name_noext
      'plugin'
    end
  end
end
