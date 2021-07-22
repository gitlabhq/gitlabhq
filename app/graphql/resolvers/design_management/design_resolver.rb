# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignResolver < BaseResolver
      type ::Types::DesignManagement::DesignType, null: true

      requires_argument!

      argument :id, ::Types::GlobalIDType[::DesignManagement::Design],
               required: false,
               description: 'Find a design by its ID.'

      argument :filename, GraphQL::Types::String,
               required: false,
               description: 'Find a design by its filename.'

      def resolve(filename: nil, id: nil)
        params = parse_args(filename, id)

        build_finder(params).execute.first
      end

      def self.single
        self
      end

      private

      def issue
        object.issue
      end

      def build_finder(params)
        ::DesignManagement::DesignsFinder.new(issue, current_user, params)
      end

      def error(msg)
        raise ::Gitlab::Graphql::Errors::ArgumentError, msg
      end

      def parse_args(filename, id)
        provided = [filename, id].map(&:present?)

        if provided.none?
          error('one of id or filename must be passed')
        elsif provided.all?
          error('only one of id or filename may be passed')
        elsif filename.present?
          { filenames: [filename] }
        else
          { ids: [parse_gid(id)] }
        end
      end

      def parse_gid(gid)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        gid = ::Types::GlobalIDType[::DesignManagement::Design].coerce_isolated_input(gid)

        gid.model_id
      end
    end
  end
end
