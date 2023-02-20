# frozen_string_literal: true

module PackageMetadata
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    def self.table_name_prefix
      'pm_'
    end
  end
end
