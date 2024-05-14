# frozen_string_literal: true

class Namespace::Detail < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_details
  belongs_to :creator, class_name: "User", optional: true
  validates :namespace, presence: true
  validates :description, length: { maximum: 255 }

  self.primary_key = :namespace_id
end

Namespace::Detail.prepend_mod
