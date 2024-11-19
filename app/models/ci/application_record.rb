# frozen_string_literal: true

module Ci
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    connects_to database: { writing: :ci, reading: :ci } if Gitlab::Database.has_config?(:ci)

    def self.table_name_prefix
      'ci_'
    end

    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, name.demodulize)
    end
  end
end
