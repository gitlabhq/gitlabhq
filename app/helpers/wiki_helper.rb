# frozen_string_literal: true

module WikiHelper
  include API::Helpers::RelatedResourcesHelpers

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
        add_to_breadcrumb_dropdown link_to(WikiPage.unhyphenize(dir_or_page).capitalize, wiki_page_path(@wiki, current_slug)), location: :after
      end
  end

  def wiki_page_errors(error)
    return unless error

    content_tag(:div, class: 'alert alert-danger') do
      case error
      when WikiPage::PageChangedError
        page_link = link_to s_("WikiPageConflictMessage|the page"), wiki_page_path(@wiki, @page), target: "_blank"
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

  def wiki_attachment_upload_url
    expose_url(api_v4_projects_wikis_attachments_path(id: @wiki.container.id))
  end

  def wiki_sort_controls(wiki, sort, direction)
    sort ||= Wiki::TITLE_ORDER
    link_class = 'btn btn-default has-tooltip reverse-sort-btn qa-reverse-sort rspec-reverse-sort'
    reversed_direction = direction == 'desc' ? 'asc' : 'desc'
    icon_class = direction == 'desc' ? 'highest' : 'lowest'

    link_to(wiki_path(wiki, action: :pages, sort: sort, direction: reversed_direction),
      type: 'button', class: link_class, title: _('Sort direction')) do
      sprite_icon("sort-#{icon_class}", size: 16)
    end
  end

  def wiki_sort_title(key)
    if key == Wiki::CREATED_AT_ORDER
      s_("Wiki|Created date")
    else
      s_("Wiki|Title")
    end
  end

  def wiki_empty_state_messages(wiki)
    case wiki.container
    when Project
      {
        writable: {
          title: s_('WikiEmpty|The wiki lets you write documentation for your project'),
          body: s_("WikiEmpty|A wiki is where you can store all the details about your project. This can include why you've created it, its principles, how to use it, and so on.")
        },
        issuable: {
          title: s_('WikiEmpty|This project has no wiki pages'),
          body: s_('WikiEmptyIssueMessage|You must be a project member in order to add wiki pages. If you have suggestions for how to improve the wiki for this project, consider opening an issue in the %{issues_link}.')
        },
        readonly: {
          title: s_('WikiEmpty|This project has no wiki pages'),
          body: s_('WikiEmpty|You must be a project member in order to add wiki pages.')
        }
      }
    when Group
      {
        writable: {
          title: s_('WikiEmpty|The wiki lets you write documentation for your group'),
          body: s_("WikiEmpty|A wiki is where you can store all the details about your group. This can include why you've created it, its principles, how to use it, and so on.")
        },
        issuable: {
          title: s_('WikiEmpty|This group has no wiki pages'),
          body: s_('WikiEmptyIssueMessage|You must be a group member in order to add wiki pages. If you have suggestions for how to improve the wiki for this group, consider opening an issue in the %{issues_link}.')
        },
        readonly: {
          title: s_('WikiEmpty|This group has no wiki pages'),
          body: s_('WikiEmpty|You must be a group member in order to add wiki pages.')
        }
      }
    else
      raise NotImplementedError, "Unknown wiki container type #{wiki.container.class.name}"
    end
  end
end
