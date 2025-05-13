# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchModelLoader
        attr_reader :model_class, :model_id, :preloads, :default_value

        def initialize(model_class, model_id, preloads = nil, default_value: nil)
          @model_class = model_class
          @model_id = model_id
          @preloads = preloads || []
          @default_value = default_value
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
            results = results.index_by(&:id)

            keys_by_id.each do |id, keys|
              keys.each { |k| loader.call(k, results[id] || default_value) }
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
