# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module WorkItems
      module BaseTypeImporter
        def self.import
          WorkItem::Type::BASE_TYPES.each do |type, attributes|
            WorkItem::Type.create!(base_type: type, **attributes.slice(:name, :icon_name))
          end
        end
      end
    end
  end
end
