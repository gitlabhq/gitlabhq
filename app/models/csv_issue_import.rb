# frozen_string_literal: true

class CsvIssueImport < ApplicationRecord
  belongs_to :project, optional: false
  belongs_to :user, optional: false
end
