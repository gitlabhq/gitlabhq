# frozen_string_literal: true

require_relative '../../tooling/danger/experiments'

module Danger
  class Experiments < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Experiments
  end
end
