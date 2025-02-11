# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'
require 'connection_pool'
require 'pg'
require 'zeitwerk'
require 'active_record'
loader = Zeitwerk::Loader.for_gem
loader.setup

module ActiveContext
  def self.configure(...)
    ActiveContext::Config.configure(...)
  end

  def self.config
    ActiveContext::Config.current
  end

  def self.adapter
    ActiveContext::Adapter.current
  end

  def self.queues
    ActiveContext::Queues.queues
  end

  def self.raw_queues
    ActiveContext::Queues.raw_queues
  end

  def self.track!(*objects, collection: nil, queue: nil)
    ActiveContext::Tracker.track!(*objects, collection: collection, queue: queue)
  end
end
