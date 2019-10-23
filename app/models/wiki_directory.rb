# frozen_string_literal: true

class WikiDirectory
  include StaticModel
  include ActiveModel::Validations

  attr_accessor :slug, :pages

  validates :slug, presence: true

  # StaticModel overrides and configuration:

  def self.primary_key
    'slug'
  end

  def id
    "#{slug}@#{last_version&.sha}"
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, 'wiki_dir')
  end

  alias_method :to_param, :slug
  alias_method :title, :slug

  # Sorts and groups pages by directory.
  #
  # pages - an array of WikiPage objects.
  #
  # Returns an array of WikiPage and WikiDirectory objects.
  # The entries are sorted in the order of the input array, where
  # directories appear in the position of their first member.
  def self.group_by_directory(pages)
    grouped = []
    dirs = Hash.new do |h, k|
      new(k).tap { |dir| grouped << (h[k] = dir) }
    end

    Array.wrap(pages).each_with_object(grouped) do |page, top_level|
      group = page.directory.present? ? dirs[page.directory] : top_level

      group << page
    end
  end

  def initialize(slug, pages = [])
    @slug = slug
    @pages = pages
  end

  def <<(page)
    @pages << page
    @last_version = nil
  end

  def last_version
    @last_version ||= @pages.map(&:last_version).max_by(&:authored_date)
  end

  def page_count
    @pages.size
  end

  def empty?
    page_count.zero?
  end

  def to_partial_path(context = nil)
    name = [context, 'wiki_directory'].compact.join('_')

    "projects/wiki_directories/#{name}"
  end
end
