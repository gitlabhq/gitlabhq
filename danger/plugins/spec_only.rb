# frozen_string_literal: true

require_relative '../../tooling/danger/spec_only'

module Danger
  class SpecOnly < ::Danger::Plugin
    include Tooling::Danger::SpecOnly
  end
end
