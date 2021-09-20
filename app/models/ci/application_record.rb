# frozen_string_literal: true

module Ci
  class ApplicationRecord < ::ApplicationRecord
    self.gitlab_schema = :gitlab_ci
    self.abstract_class = true

    def self.table_name_prefix
      'ci_'
    end

    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, self.name.demodulize)
    end
  end
end
