# frozen_string_literal: true

require_relative '../../tooling/danger/sidekiq_queues'

module Danger
  class SidekiqQueues < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::SidekiqQueues
  end
end
