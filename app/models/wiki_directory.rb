class WikiDirectory
  include ActiveModel::Validations

  attr_accessor :slug, :pages, :directories

  validates :slug, presence: true

  def initialize(slug, pages = [], directories = [])
    @slug = slug
    @pages = pages
    @directories = directories
  end

  # Relative path to the partial to be used when rendering collections
  # of this object.
  def to_partial_path
    'projects/wikis/wiki_directory'
  end
end
