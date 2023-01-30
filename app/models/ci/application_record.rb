# frozen_string_literal: true

module Ci
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    if Gitlab::Database.has_config?(:ci)
      connects_to database: { writing: :ci, reading: :ci }
    end

    def self.table_name_prefix
      'ci_'
    end

    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, name.demodulize)
    end
  end
end
