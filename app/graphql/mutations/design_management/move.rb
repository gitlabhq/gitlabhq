# frozen_string_literal: true

module Mutations
  module DesignManagement
    class Move < ::Mutations::BaseMutation
      graphql_name "DesignManagementMove"

      DesignID = ::Types::GlobalIDType[::DesignManagement::Design]

      argument :id, DesignID, required: true, as: :current_design,
               description: "ID of the design to move"

      argument :previous, DesignID, required: false, as: :previous_design,
               description: "ID of the immediately preceding design"

      argument :next, DesignID, required: false, as: :next_design,
               description: "ID of the immediately following design"

      field :design_collection, Types::DesignManagement::DesignCollectionType,
            null: true,
            description: "The current state of the collection"

      def ready(*)
        raise ::Gitlab::Graphql::Errors::ResourceNotAvailable unless ::Feature.enabled?(:reorder_designs)
      end

      def resolve(**args)
        service = ::DesignManagement::MoveDesignsService.new(current_user, parameters(args))

        { design_collection: service.collection, errors: service.execute.errors }
      end

      private

      def parameters(**args)
        args.transform_values { |id| GitlabSchema.find_by_gid(id) }.transform_values(&:sync).tap do |hash|
          hash.each { |k, design| not_found(args[k]) unless current_user.can?(:read_design, design) }
        end
      end

      def not_found(gid)
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, "Resource not available: #{gid}"
      end
    end
  end
end
