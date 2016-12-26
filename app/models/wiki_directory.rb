class WikiDirectory
  include ActiveModel::Validations

  attr_accessor :slug, :pages, :directories

  validates :slug, presence: true

  def initialize(slug, pages = [], directories = [])
    @slug = slug
    @pages = pages
    @directories = directories
  end
end
