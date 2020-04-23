# frozen_string_literal: true

class Sprint < ApplicationRecord
  belongs_to :project
  belongs_to :group
end
