# frozen_string_literal: true

module WikiHelper
  include API::Helpers::RelatedResourcesHelpers

  def wiki_page_title(page, action = nil)
    titles = [_('Wiki')]

    if page.persisted?
      titles << page.human_title
      breadcrumb_title(page.human_title)
      wiki_breadcrumb_dropdown_links(page.slug)
    end

    titles << action if action
    page_title(*titles.reverse)
    add_to_breadcrumbs(_('Wiki'), wiki_path(page.wiki))
  end

  def link_to_wiki_page(page, **options)
    link_to page.human_title, wiki_page_path(page.wiki, page), **options
  end

  def wiki_sidebar_toggle_button
    content_tag :button, class: 'gl-button btn btn-default btn-icon sidebar-toggle js-sidebar-wiki-toggle', role: 'button', type: 'button' do
      sprite_icon('chevron-double-lg-left')
    end
  end

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

  def wiki_attachment_upload_url
    case @wiki.container
    when Project
      expose_url(api_v4_projects_wikis_attachments_path(id: @wiki.container.id))
    else
      raise TypeError, "Unsupported wiki container #{@wiki.container.class}"
    end
  end

  def wiki_sort_controls(wiki, sort, direction)
    sort ||= Wiki::TITLE_ORDER
    link_class = 'gl-button btn btn-default btn-icon has-tooltip reverse-sort-btn qa-reverse-sort rspec-reverse-sort'
    reversed_direction = direction == 'desc' ? 'asc' : 'desc'
    icon_class = direction == 'desc' ? 'highest' : 'lowest'

    link_to(wiki_path(wiki, action: :pages, sort: sort, direction: reversed_direction),
      type: 'button', class: link_class, title: _('Sort direction')) do
      sprite_icon("sort-#{icon_class}")
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
      writable_body = s_("WikiEmpty|A wiki is where you can store all the details about your project. This can include why you've created it, its principles, how to use it, and so on.")
      writable_body += s_("WikiEmpty| Have a Confluence wiki already? Use that instead.") if show_enable_confluence_integration?(wiki.container)

      {
        writable: {
          title: s_('WikiEmpty|The wiki lets you write documentation for your project'),
          body: writable_body
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

  def wiki_page_tracking_context(page)
    {
      'wiki-format'               => page.format,
      'wiki-title-size'           => page.title.bytesize,
      'wiki-content-size'         => page.raw_content.bytesize,
      'wiki-directory-nest-level' => page.path.scan('/').count,
      'wiki-container-type'       => page.wiki.container.class.name
    }
  end

  def show_enable_confluence_integration?(container)
    container.is_a?(Project) &&
      current_user&.can?(:admin_project, container) &&
      !container.has_confluence?
  end
end

WikiHelper.prepend_mod_with('WikiHelper')
