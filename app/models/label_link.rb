class LabelLink < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :label

  validates :target, presence: true
  validates :label, presence: true
end
