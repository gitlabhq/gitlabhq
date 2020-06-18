# frozen_string_literal: true

class WikiDirectory
  include ActiveModel::Validations

  attr_accessor :slug, :pages

  validates :slug, presence: true

  def initialize(slug, pages = [])
    @slug = slug
    @pages = pages
  end

  # Relative path to the partial to be used when rendering collections
  # of this object.
  def to_partial_path
    '../shared/wikis/wiki_directory'
  end
end
