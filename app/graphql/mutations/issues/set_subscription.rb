# frozen_string_literal: true

module Mutations
  module Issues
    class SetSubscription < Base
      graphql_name 'IssueSetSubscription'

      include ResolvesSubscription
    end
  end
end
