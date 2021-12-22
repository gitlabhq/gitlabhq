# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module WorkItems
      module BaseTypeImporter
        def self.import
          ::WorkItems::Type::BASE_TYPES.each do |type, attributes|
            ::WorkItems::Type.create!(base_type: type, **attributes.slice(:name, :icon_name))
          end
        end
      end
    end
  end
end
