# frozen_string_literal: true

class Release < ActiveRecord::Base
  include CacheMarkdownField

  cache_markdown_field :description

  belongs_to :project

  validates :description, :project, :tag, presence: true
end
