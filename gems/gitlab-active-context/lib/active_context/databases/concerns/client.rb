# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Client
        DEFAULT_PREFIX = 'gitlab_active_context'

        attr_reader :options

        def prefix
          options[:prefix] || DEFAULT_PREFIX
        end

        def search(_)
          raise NotImplementedError
        end
      end
    end
  end
end
