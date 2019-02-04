# frozen_string_literal: true

class ProjectPathValidator < AbstractPathValidator
  extend Gitlab::EncodingHelper

  def self.path_regex
    Gitlab::PathRegex.full_project_path_regex
  end

  def self.format_regex
    Gitlab::PathRegex.project_path_format_regex
  end

  def self.format_error_message
    Gitlab::PathRegex.project_path_format_message
  end
end
