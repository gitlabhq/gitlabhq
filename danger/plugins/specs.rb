# frozen_string_literal: true

require_relative '../../tooling/danger/specs'

module Danger
  class Specs < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Specs
  end
end
