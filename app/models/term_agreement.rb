# frozen_string_literal: true

class TermAgreement < ApplicationRecord
  belongs_to :term, class_name: 'ApplicationSetting::Term'
  belongs_to :user

  scope :accepted, -> { where(accepted: true) }

  validates :user, :term, presence: true
end
