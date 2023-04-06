# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class SchemaInconsistency < ApplicationRecord
        self.table_name = :schema_inconsistencies

        belongs_to :issue

        validates :object_name, :valitador_name, :table_name, presence: true
      end
    end
  end
end
