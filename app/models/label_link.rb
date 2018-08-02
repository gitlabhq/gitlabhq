# frozen_string_literal: true

class LabelLink < ActiveRecord::Base
  include Importable

  belongs_to :target, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :label

  validates :target, presence: true, unless: :importing?
  validates :label, presence: true, unless: :importing?
end
