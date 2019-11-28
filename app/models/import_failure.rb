# frozen_string_literal: true

class ImportFailure < ApplicationRecord
  belongs_to :project

  validates :project, presence: true
end
