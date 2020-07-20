# frozen_string_literal: true

require_relative '../../lib/gitlab/danger/sidekiq_queues'

module Danger
  class SidekiqQueues < Plugin
    # Put the helper code somewhere it can be tested
    include Gitlab::Danger::SidekiqQueues
  end
end
