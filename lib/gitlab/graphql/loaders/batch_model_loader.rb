# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchModelLoader
        attr_reader :model_class, :model_id, :preloads

        def initialize(model_class, model_id, preloads = nil)
          @model_class = model_class
          @model_id = model_id
          @preloads = preloads || []
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find
          BatchLoader::GraphQL.for([model_id.to_i, preloads]).batch(key: model_class) do |for_params, loader, args|
            model = args[:key]
            keys_by_id = for_params.group_by(&:first)
            ids = for_params.map(&:first)
            preloads = for_params.flat_map(&:second).uniq
            results = model.where(id: ids)
            results = results.preload(*preloads) unless preloads.empty?

            results.each do |record|
              keys_by_id.fetch(record.id, []).each { |k| loader.call(k, record) }
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
