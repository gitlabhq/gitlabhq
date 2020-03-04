# frozen_string_literal: true

class UserDetail < ApplicationRecord
  belongs_to :user

  validates :job_title, length: { maximum: 200 }
end
