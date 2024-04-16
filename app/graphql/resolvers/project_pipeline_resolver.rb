# frozen_string_literal: true

module Resolvers
  class ProjectPipelineResolver < BaseResolver
    include LooksAhead

    type ::Types::Ci::PipelineType, null: true

    alias_method :project, :object

    argument :iid, GraphQL::Types::ID,
             required: false,
             description: 'IID of the Pipeline. For example, "1".'

    argument :sha, GraphQL::Types::String,
             required: false,
             description: 'SHA of the Pipeline. For example, "dyd0f15ay83993f5ab66k927w28673882x99100b".'

    def ready?(iid: nil, sha: nil, **args)
      raise Gitlab::Graphql::Errors::ArgumentError, 'Provide one of an IID or SHA' unless iid.present? ^ sha.present?

      super
    end

    def resolve(iid: nil, sha: nil, **args)
      self.lookahead = args.delete(:lookahead)

      if iid
        BatchLoader::GraphQL.for(iid).batch(key: project) do |iids, loader|
          finder = ::Ci::PipelinesFinder.new(project, current_user, iids: iids)

          apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.iid.to_s, pipeline) }
        end
      else
        BatchLoader::GraphQL.for(sha).batch(key: project) do |shas, loader|
          finder = ::Ci::PipelinesFinder.new(project, current_user, sha: shas)

          apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.sha.to_s, pipeline) }
        end
      end
    end

    def unconditional_includes
      [
        { statuses: [:needs] }
      ]
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = super
      complexity - 10
    end
  end
end
