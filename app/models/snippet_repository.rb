# frozen_string_literal: true

class SnippetRepository < ApplicationRecord
  include Shardable

  belongs_to :snippet, inverse_of: :snippet_repository

  class << self
    def find_snippet(disk_path)
      find_by(disk_path: disk_path)&.snippet
    end
  end
end
