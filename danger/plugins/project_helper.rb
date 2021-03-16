# frozen_string_literal: true

require_relative '../../tooling/danger/project_helper'

module Danger
  # Common helper functions for our danger scripts. See Tooling::Danger::ProjectHelper
  # for more details
  class ProjectHelper < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::ProjectHelper
  end
end
