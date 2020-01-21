# frozen_string_literal: true

class ImportFailure < ApplicationRecord
  belongs_to :project
  belongs_to :group

  validates :project, presence: true, unless: :group
  validates :group, presence: true, unless: :project
end
