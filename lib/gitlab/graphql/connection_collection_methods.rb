# frozen_string_literal: true

module Gitlab
  module Graphql
    module ConnectionCollectionMethods
      extend ActiveSupport::Concern

      included do
        delegate :to_a, :size, :map, :include?, :empty?, to: :nodes
      end
    end
  end
end
