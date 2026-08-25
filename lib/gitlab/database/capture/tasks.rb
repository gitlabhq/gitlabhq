# frozen_string_literal: true

module Gitlab
  module Database
    module Capture
      class Tasks
        include Singleton

        class << self
          delegate :[], :[]=, to: :instance
        end

        def initialize
          @tasks = {}
          @mutex = Mutex.new
        end

        def [](database_name)
          @mutex.synchronize do
            @tasks[database_name]
          end
        end

        def []=(database_name, capture)
          @mutex.synchronize do
            @tasks[database_name] = capture
          end
        end
      end
    end
  end
end
