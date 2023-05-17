# frozen_string_literal: true

require_relative '../../tooling/danger/sidekiq_args'

module Danger
  class SidekiqArgs < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::SidekiqArgs
  end
end
