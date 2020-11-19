# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      module GetGroupQuery
        extend self

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            group(fullPath: $full_path) {
              name
              path
              fullPath
              description
              visibility
              emailsDisabled
              lfsEnabled
              mentionsDisabled
              projectCreationLevel
              requestAccessEnabled
              requireTwoFactorAuthentication
              shareWithGroupLock
              subgroupCreationLevel
              twoFactorGracePeriod
            }
          }
          GRAPHQL
        end

        def variables
          { full_path: :source_full_path }
        end
      end
    end
  end
end
