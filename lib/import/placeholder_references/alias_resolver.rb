# frozen_string_literal: true

module Import
  module PlaceholderReferences
    module AliasResolver
      MissingAlias = Class.new(StandardError)

      ALIASES = {
        "Note" => {
          model: Note,
          columns: {
            "author_id" => "author_id"
          }
        }
      }.freeze

      def self.aliased_model(model)
        aliased_model = ALIASES.dig(model, :model)
        return aliased_model if aliased_model.present?

        message = "ALIASES must be extended to include #{model}"
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(MissingAlias.new(message))

        model.safe_constantize
      end

      def self.aliased_column(model, column)
        aliased_column = ALIASES.dig(model, :columns, column)
        return aliased_column if aliased_column.present?

        message = "ALIASES must be extended to include #{model} #{column}"
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(MissingAlias.new(message))

        column
      end
    end
  end
end
