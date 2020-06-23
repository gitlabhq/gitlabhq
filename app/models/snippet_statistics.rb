# frozen_string_literal: true

class SnippetStatistics < ApplicationRecord
  belongs_to :snippet

  validates :snippet, presence: true
end
