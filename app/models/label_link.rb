class LabelLink < ActiveRecord::Base
  include Importable

  belongs_to :target, polymorphic: true
  belongs_to :label

  validates :target, presence: true, unless: :importing?
  validates :label, presence: true, unless: :importing?
end
