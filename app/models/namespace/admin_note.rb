# frozen_string_literal: true

class Namespace::AdminNote < ApplicationRecord
  belongs_to :namespace, inverse_of: :admin_note
  validates :namespace, presence: true
  validates :note, length: { maximum: 1000 }
end
