# frozen_string_literal: true

module Resolvers
  module DesignManagement
    module Version
      # Resolver for DesignAtVersion objects given an implicit version context
      class DesignsAtVersionResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        type Types::DesignManagement::DesignAtVersionType, null: true

        authorize :read_design

        argument :ids,
                 [GraphQL::ID_TYPE],
                 required: false,
                 description: 'Filters designs by their ID'
        argument :filenames,
                 [GraphQL::STRING_TYPE],
                 required: false,
                 description: 'Filters designs by their filename'

        def self.single
          ::Resolvers::DesignManagement::Version::DesignAtVersionResolver
        end

        def resolve(ids: nil, filenames: nil)
          find(ids, filenames).execute.map { |d| make(d) }
        end

        private

        def find(ids, filenames)
          ids = ids&.map { |id| parse_design_id(id).model_id }

          ::DesignManagement::DesignsFinder.new(issue, current_user,
                                                ids: ids,
                                                filenames: filenames,
                                                visible_at_version: version)
        end

        def parse_design_id(id)
          GitlabSchema.parse_gid(id, expected_type: ::DesignManagement::Design)
        end

        def issue
          version.issue
        end

        def version
          object
        end

        def make(design)
          ::DesignManagement::DesignAtVersion.new(design: design, version: version)
        end
      end
    end
  end
end
