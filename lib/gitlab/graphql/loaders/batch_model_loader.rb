# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchModelLoader
        attr_reader :model_class, :model_id

        def initialize(model_class, model_id)
          @model_class = model_class
          @model_id = model_id
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find
          BatchLoader::GraphQL.for(model_id.to_i).batch(key: model_class) do |ids, loader, args|
            model = args[:key]
            results = model.where(id: ids)

            results.each { |record| loader.call(record.id, record) }
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
