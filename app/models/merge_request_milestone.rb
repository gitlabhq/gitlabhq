# frozen_string_literal: true

class MergeRequestMilestone < ApplicationRecord
  belongs_to :milestone
  belongs_to :merge_request
end
