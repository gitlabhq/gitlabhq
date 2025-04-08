# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module QueryResult
        include Enumerable

        attr_reader :user

        def initialize(result:, collection:, user:)
          @result = result
          @collection = collection
          @user = user
        end

        def authorized_results
          @authorized_results ||= collection.redact_unauthorized_results!(self)
        end

        def ids
          each.pluck('ref_id')
        end

        def each
          raise NotImplementedError
        end

        private

        attr_reader :result, :collection
      end
    end
  end
end
