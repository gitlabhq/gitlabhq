# frozen_string_literal: true

require_relative '../../tooling/danger/required_stops'

module Danger
  class RequiredStops < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::RequiredStops
  end
end
