# frozen_string_literal: true

class Release < ActiveRecord::Base
  include CacheMarkdownField

  cache_markdown_field :description

  belongs_to :project
  # releases prior to 11.7 have no author
  belongs_to :author, class_name: 'User'

  validates :description, :project, :tag, presence: true

  delegate :repository, to: :project

  def commit
    git_tag = repository.find_tag(tag)
    repository.commit(git_tag.dereferenced_target)
  end

  def sources_formats
    @sources_formats ||= %w(zip tar.gz tar.bz2 tar).freeze
  end

  # TODO: placeholder for frontend API compatibility
  def links
    []
  end

  def assets_count
    links.size + sources_formats.size
  end
end
