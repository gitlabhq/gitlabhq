# frozen_string_literal: true

class LabelPriority < ActiveRecord::Base
  belongs_to :project
  belongs_to :label

  validates :project, :label, :priority, presence: true
  validates :label_id, uniqueness: { scope: :project_id }
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
