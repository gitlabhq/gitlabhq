module WikiHelper
  # Produces a pure text breadcrumb for a given page.
  #
  # page_slug - The slug of a WikiPage object.
  #
  # Returns a String composed of the capitalized name of each directory and the
  # capitalized name of the page itself.
  def breadcrumb(page_slug)
    page_slug.split('/')
      .map { |dir_or_page| WikiPage.unhyphenize(dir_or_page).capitalize }
      .join(' / ')
  end

  def wiki_breadcrumb_dropdown_links(page_slug)
    page_slug_split = page_slug.split('/')
    page_slug_split.pop(1)
    current_slug = ""
    page_slug_split
      .map do |dir_or_page|
        current_slug = "#{current_slug}#{dir_or_page}/"
        add_to_breadcrumb_dropdown link_to(WikiPage.unhyphenize(dir_or_page).capitalize, project_wiki_path(@project, current_slug)), location: :after
      end
  end

  def wiki_page_errors(error)
    return unless error

    content_tag(:div, class: 'alert alert-danger') do
      case error
      when WikiPage::PageChangedError
        page_link = link_to s_("WikiPageConflictMessage|the page"), project_wiki_path(@project, @page), target: "_blank"
        concat(
          (s_("WikiPageConflictMessage|Someone edited the page the same time you did. Please check out %{page_link} and make sure your changes will not unintentionally remove theirs.") % { page_link: page_link }).html_safe
        )
      when WikiPage::PageRenameError
        s_("WikiEdit|There is already a page with the same title in that path.")
      else
        error.message
      end
    end
  end
end
