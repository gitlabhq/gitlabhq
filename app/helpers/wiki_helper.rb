module WikiHelper
  # Produces a pure text breadcrumb for a given page.
  #
  # page_slug - The slug of a WikiPage object.
  #
  # Returns a String composed of the capitalized name of each directory and the
  # capitalized name of the page itself.
  def breadcrumb(page_slug)
    page_slug.split('/').
      map { |dir_or_page| WikiPage.unhyphenize(dir_or_page).capitalize }.
      join(' / ')
  end
end
