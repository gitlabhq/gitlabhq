# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerResolver < BaseResolver
      include LooksAhead

      type Types::Ci::RunnerType, null: true
      description 'Runner information.'

      argument :id,
        type: ::Types::GlobalIDType[::Ci::Runner],
        required: true,
        description: 'Runner ID.'

      def resolve_with_lookahead(id:)
        find_runner(id: id)
      end

      private

      def find_runner(id:)
        preloads = []
        preloads << :creator if lookahead.selects?(:created_by)
        preloads << :tags if lookahead.selects?(:tag_list)

        runner_id = GitlabSchema.parse_gid(id, expected_type: ::Ci::Runner).model_id

        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Runner, runner_id, preloads).find
      end
    end
  end
end
