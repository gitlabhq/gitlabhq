# frozen_string_literal: true

class IssueMilestone < ApplicationRecord
  belongs_to :milestone
  belongs_to :issue
end
