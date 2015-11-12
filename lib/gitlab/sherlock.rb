require 'securerandom'

module Gitlab
  module Sherlock
    @collection = Collection.new

    class << self
      attr_reader :collection
    end

    def self.enabled?
      Rails.env.development? && !!ENV['ENABLE_SHERLOCK']
    end

    def self.enable_line_profiler?
      RUBY_ENGINE == 'ruby'
    end
  end
end
