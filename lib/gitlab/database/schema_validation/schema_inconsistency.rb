# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class SchemaInconsistency < ApplicationRecord
        self.table_name = :schema_inconsistencies

        belongs_to :issue

        validates :object_name, :valitador_name, :table_name, presence: true

        scope :with_open_issues, -> { joins(:issue).where('issue.state_id': Issue.available_states[:opened]) }
      end
    end
  end
end
