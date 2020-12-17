# frozen_string_literal: true

# A marker interface that allows use to lazily resolve a wider range of value
module Gitlab
  module Graphql
    module Deferred
      def execute
        raise NotImplementedError, 'Deferred classes must provide an execute method'
      end
    end
  end
end
