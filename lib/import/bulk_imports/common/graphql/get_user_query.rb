# frozen_string_literal: true

module Import
  module BulkImports
    module Common
      module Graphql
        class GetUserQuery
          def to_s
            <<-GRAPHQL
              query($id: UserID!) {
                user(id: $id) {
                  id
                  name
                  username
                }
              }
            GRAPHQL
          end
        end
      end
    end
  end
end
