# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetSubscription < Base
      graphql_name 'MergeRequestSetSubscription'

      include ResolvesSubscription
    end
  end
end
