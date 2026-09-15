# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectPipelineResolver < BaseResolver
      include LooksAhead

      calls_gitaly!

      type ::Types::Ci::PipelineType, null: true

      alias_method :project, :object

      argument :id, Types::GlobalIDType[::Ci::Pipeline],
        required: false,
        description: 'Global ID of the Pipeline. For example, "gid://gitlab/Ci::Pipeline/314".',
        prepare: ->(pipeline_id, _ctx) { pipeline_id.model_id }

      argument :iid, GraphQL::Types::ID, # rubocop:disable Graphql/IDType -- Legacy argument using ID type kept for backwards compatibility
        required: false,
        description: 'IID of the Pipeline. For example, "1".'

      argument :sha, GraphQL::Types::String,
        required: false,
        description: 'SHA of the Pipeline. For example, "dyd0f15ay83993f5ab66k927w28673882x99100b".'

      validates mutually_exclusive: [:id, :iid, :sha]

      def self.resolver_complexity(args, child_complexity:)
        complexity = super
        complexity - 10 if args.present?
      end

      def resolve(id: nil, iid: nil, sha: nil, **args)
        self.lookahead = args.delete(:lookahead)

        if id
          BatchLoader::GraphQL.for(id).batch(key: project) do |ids, loader|
            finder = ::Ci::PipelinesFinder.new(project, current_user, ids: ids)

            apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.id.to_s, pipeline) }
          end
        elsif iid
          BatchLoader::GraphQL.for(iid).batch(key: project) do |iids, loader|
            finder = ::Ci::PipelinesFinder.new(project, current_user, iids: iids)

            apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.iid.to_s, pipeline) }
          end
        elsif sha
          BatchLoader::GraphQL.for(sha).batch(key: project) do |shas, loader|
            finder = ::Ci::PipelinesFinder.new(project, current_user, sha: shas)

            apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.sha.to_s, pipeline) }
          end
        else
          project.last_pipeline
        end
      end

      def unconditional_includes
        [
          { statuses: [:needs] }
        ]
      end
    end
  end
end
