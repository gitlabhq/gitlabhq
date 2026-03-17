# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  module TestCoercers
    class CommaSeparatedToArray
      def self.coerce
        ->(value) do
          case value
          when String
            value.split(",").map(&:strip)
          when Array
            value.flat_map { |v| v.to_s.split(",").map(&:strip) }
          else
            []
          end
        end
      end
    end

    class CommaSeparatedToIntegerArray
      def self.coerce
        ->(value) do
          CommaSeparatedToArray.coerce.call(value).map(&:to_i)
        end
      end
    end
  end

  class CoercedParamsApi < Grape::API
    desc "Get items with comma-separated labels" do
      detail "Returns items filtered by labels"
      success code: 200
      tags %w[coerced_params]
    end
    params do
      optional :labels, type: [String],
        coerce_with: TestCoercers::CommaSeparatedToArray.coerce,
        desc: "Comma-separated list of label names"
      optional :ids, type: [Integer],
        coerce_with: TestCoercers::CommaSeparatedToIntegerArray.coerce,
        desc: "Comma-separated list of IDs"
      optional :status, type: String, desc: "Filter by status"
    end
    get "/api/:version/items" do
      status 200
      []
    end

    desc "Create item with comma-separated labels" do
      detail "Creates an item with labels"
      success code: 201
      tags %w[coerced_params]
    end
    params do
      requires :name, type: String, desc: "Item name"
      optional :labels, type: [String],
        coerce_with: TestCoercers::CommaSeparatedToArray.coerce,
        desc: "Comma-separated list of label names"
      optional :ids, type: [Integer],
        coerce_with: TestCoercers::CommaSeparatedToIntegerArray.coerce,
        desc: "Comma-separated list of IDs"
    end
    post "/api/:version/items" do
      status 201
      {}
    end

    desc "Delete items" do
      detail "Deletes items by IDs"
      success code: 204
      tags %w[coerced_params]
    end
    params do
      optional :ids, type: [Integer],
        coerce_with: TestCoercers::CommaSeparatedToIntegerArray.coerce,
        desc: "Comma-separated list of IDs to delete"
    end
    delete "/api/:version/items" do
      status 204
      nil
    end
  end
end
# rubocop:enable API/Base
