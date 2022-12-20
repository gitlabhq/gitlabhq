# frozen_string_literal: true

require_relative '../../tooling/danger/stable_branch'

module Danger
  class StableBranch < ::Danger::Plugin
    include Tooling::Danger::StableBranch
  end
end
