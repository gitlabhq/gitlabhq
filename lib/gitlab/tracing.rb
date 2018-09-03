require_relative 'tracing/redis_tracing'
require_relative 'tracing/rails_tracing'

module Gitlab
  module Tracing
    def self.enabled?
      return true
    end
  end
end

