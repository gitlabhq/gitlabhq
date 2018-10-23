# frozen_string_literal: true

module Gitlab
  class EnvironmentLogger < Gitlab::Logger
    def self.file_name_noext
      Rails.env
    end
  end
end
