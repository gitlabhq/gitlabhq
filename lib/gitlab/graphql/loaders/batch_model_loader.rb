# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchModelLoader
        attr_reader :model_class, :model_id

        def initialize(model_class, model_id)
          @model_class, @model_id = model_class, model_id
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find
          BatchLoader.for({ model: model_class, id: model_id.to_i }).batch do |loader_info, loader|
            per_model = loader_info.group_by { |info| info[:model] }
            per_model.each do |model, info|
              ids = info.map { |i| i[:id] }
              results = model.where(id: ids)

              results.each { |record| loader.call({ model: model, id: record.id }, record) }
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
