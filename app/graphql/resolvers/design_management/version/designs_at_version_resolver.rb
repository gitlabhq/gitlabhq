# frozen_string_literal: true

module Resolvers
  module DesignManagement
    module Version
      # Resolver for DesignAtVersion objects given an implicit version context
      class DesignsAtVersionResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        type Types::DesignManagement::DesignAtVersionType, null: true

        authorize :read_design

        DesignID = ::Types::GlobalIDType[::DesignManagement::Design]

        argument :filenames,
          [GraphQL::Types::String],
          required: false,
          description: 'Filters designs by their filename.'
        argument :ids, [DesignID],
          required: false,
          description: 'Filters designs by their ID.'

        def self.single
          ::Resolvers::DesignManagement::Version::DesignAtVersionResolver
        end

        def resolve(ids: nil, filenames: nil)
          find(ids, filenames).execute.map { |d| make(d) }
        end

        private

        def find(ids, filenames)
          ::DesignManagement::DesignsFinder.new(issue, current_user,
            ids: design_ids(ids),
            filenames: filenames,
            visible_at_version: version)
        end

        def design_ids(gids)
          return if gids.nil?

          gids.map(&:model_id)
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
