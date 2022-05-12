# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module WorkItems
      module BaseTypeImporter
        def self.upsert_types
          current_time = Time.current

          base_types = ::WorkItems::Type::BASE_TYPES.map do |type, attributes|
            attributes.slice(:name, :icon_name)
                      .merge(created_at: current_time, updated_at: current_time, base_type: type)
          end

          ::WorkItems::Type.upsert_all(
            base_types,
            unique_by: :idx_work_item_types_on_namespace_id_and_name_null_namespace
          )
        end
      end
    end
  end
end
