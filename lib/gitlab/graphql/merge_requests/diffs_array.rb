# frozen_string_literal: true

module Gitlab
  module Graphql
    module MergeRequests
      class DiffsArray < ::Gitlab::Graphql::ExternallyPaginatedArray
        attr_reader :overflow

        def initialize(*args, overflow: nil, **kwargs)
          super(*args, **kwargs)
          @overflow = overflow
        end
      end
    end
  end
end
