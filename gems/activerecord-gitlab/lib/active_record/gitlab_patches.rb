# frozen_string_literal: true

require "active_record"
require_relative "gitlab_patches/version"
require_relative "gitlab_patches/rescue_from"

module ActiveRecord
  module GitlabPatches
  end
end
