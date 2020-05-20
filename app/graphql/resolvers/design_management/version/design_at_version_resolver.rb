# frozen_string_literal: true

module Resolvers
  module DesignManagement
    module Version
      # Resolver for a DesignAtVersion object given an implicit version context
      class DesignAtVersionResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        type Types::DesignManagement::DesignAtVersionType, null: true

        authorize :read_design

        argument :id, GraphQL::ID_TYPE,
                 required: false,
                 as: :design_at_version_id,
                 description: 'The ID of the DesignAtVersion'
        argument :design_id, GraphQL::ID_TYPE,
                 required: false,
                 description: 'The ID of a specific design'
        argument :filename, GraphQL::STRING_TYPE,
                 required: false,
                 description: 'The filename of a specific design'

        def self.single
          self
        end

        def resolve(design_id: nil, filename: nil, design_at_version_id: nil)
          validate_arguments(design_id, filename, design_at_version_id)

          return unless Ability.allowed?(current_user, :read_design, issue)
          return specific_design_at_version(design_at_version_id) if design_at_version_id

          find(design_id, filename).map { |d| make(d) }.first
        end

        private

        def validate_arguments(design_id, filename, design_at_version_id)
          args = { filename: filename, id: design_at_version_id, design_id: design_id }
          passed = args.compact.keys

          return if passed.size == 1

          msg = "Exactly one of #{args.keys.join(', ')} expected, got #{passed}"

          raise Gitlab::Graphql::Errors::ArgumentError, msg
        end

        def specific_design_at_version(id)
          dav = GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::DesignAtVersion)
          return unless consistent?(dav)

          dav
        end

        # Test that the DAV found by ID actually belongs on this version, and
        # that it is visible at this version.
        def consistent?(dav)
          return false unless dav.present?

          dav.design.issue_id == issue.id &&
            dav.version.id == version.id &&
            dav.design.visible_in?(version)
        end

        def find(id, filename)
          ids = [parse_design_id(id).model_id] if id
          filenames = [filename] if filename

          ::DesignManagement::DesignsFinder
            .new(issue, current_user, ids: ids, filenames: filenames, visible_at_version: version)
            .execute
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
