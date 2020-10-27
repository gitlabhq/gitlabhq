# frozen_string_literal: true

class Issues::CsvImport < ApplicationRecord
  self.table_name = 'csv_issue_imports'

  belongs_to :project, optional: false
  belongs_to :user, optional: false
end
