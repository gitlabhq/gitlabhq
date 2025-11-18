# frozen_string_literal: true

require "active_record"
require_relative "gitlab_patches/version"
require_relative "gitlab_patches/rescue_from"
require_relative "gitlab_patches/relation/find_or_create_by"
require_relative "gitlab_patches/partitioning"

module ActiveRecord
  module GitlabPatches
  end
end
