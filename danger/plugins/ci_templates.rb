# frozen_string_literal: true

require_relative '../../tooling/danger/ci_templates'

module Danger
  class CiTemplates < ::Danger::Plugin
    include Tooling::Danger::CiTemplates
  end
end
