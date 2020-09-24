# frozen_string_literal: true

class WikiDirectory
  include ActiveModel::Validations

  attr_accessor :slug, :entries

  validates :slug, presence: true

  # Groups a list of wiki pages into a nested collection of WikiPage and WikiDirectory objects,
  # preserving the order of the passed pages.
  #
  # Returns an array with all entries for the toplevel directory.
  #
  # @param [Array<WikiPage>] pages
  # @return [Array<WikiPage, WikiDirectory>]
  #
  def self.group_pages(pages)
    # Build a hash to map paths to created WikiDirectory objects,
    # and recursively create them for each level of the path.
    # For the toplevel directory we use '' as path, as that's what WikiPage#directory returns.
    directories = Hash.new do |_, path|
      directories[path] = new(path).tap do |directory|
        if path.present?
          parent = File.dirname(path)
          parent = '' if parent == '.'
          directories[parent].entries << directory
        end
      end
    end

    pages.each do |page|
      directories[page.directory].entries << page
    end

    directories[''].entries
  end

  def initialize(slug, entries = [])
    @slug = slug
    @entries = entries
  end

  def title
    WikiPage.unhyphenize(File.basename(slug))
  end

  # Relative path to the partial to be used when rendering collections
  # of this object.
  def to_partial_path
    '../shared/wikis/wiki_directory'
  end
end
