# frozen_string_literal: true

class UserDetail < ApplicationRecord
  belongs_to :user

  validates :job_title, presence: true, length: { maximum: 200 }
end
