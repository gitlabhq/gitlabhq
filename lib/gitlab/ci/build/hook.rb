# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Hook
        attr_reader :name, :script

        class << self
          def from_hooks(job)
            job.options[:hooks].to_a.map do |name, script|
              new(name.to_s, script)
            end
          end
        end

        def initialize(name, script)
          @name = name
          @script = script
        end
      end
    end
  end
end
