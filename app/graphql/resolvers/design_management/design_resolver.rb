# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignResolver < BaseResolver
      argument :id, GraphQL::ID_TYPE,
               required: false,
               description: 'Find a design by its ID'

      argument :filename, GraphQL::STRING_TYPE,
               required: false,
               description: 'Find a design by its filename'

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
        GitlabSchema.parse_gid(gid, expected_type: ::DesignManagement::Design).model_id
      end
    end
  end
end
