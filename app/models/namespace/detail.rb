# frozen_string_literal: true

class Namespace::Detail < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_details
  validates :namespace, presence: true
  validates :description, length: { maximum: 255 }

  self.primary_key = :namespace_id
end

Namespace::Detail.prepend_mod
