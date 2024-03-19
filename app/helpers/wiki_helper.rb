# frozen_string_literal: true

module WikiHelper
  include API::Helpers::RelatedResourcesHelpers

  def wiki_page_title(page, action = nil)
    titles = [_('Wiki')]

    if page.persisted?
      titles << page.human_title
      breadcrumb_title(page.human_title)
      wiki_breadcrumb_collapsed_links(page.slug)
    end

    titles << action if action
    page_title(*titles.reverse)
    add_to_breadcrumbs(_('Wiki'), wiki_path(page.wiki))
  end

  def link_to_wiki_page(page, **options)
    link_to page.human_title, wiki_page_path(page.wiki, page), **options
  end

  def wiki_sidebar_toggle_button
    render Pajamas::ButtonComponent.new(icon: 'chevron-double-lg-left', button_options: { class: 'sidebar-toggle js-sidebar-wiki-toggle' })
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

  def wiki_breadcrumb_collapsed_links(page_slug)
    page_slug_split = page_slug.split('/')
    page_slug_split.pop(1)
    current_slug = ""
    page_slug_split
      .map do |dir_or_page|
        current_slug = "#{current_slug}#{dir_or_page}/"
        add_to_breadcrumb_collapsed_links link_to(WikiPage.unhyphenize(dir_or_page).capitalize, wiki_page_path(@wiki, current_slug)), location: :after
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

  def wiki_sort_controls(wiki, direction, action: :pages)
    link_class = 'has-tooltip reverse-sort-btn rspec-reverse-sort'
    reversed_direction = direction == 'desc' ? 'asc' : 'desc'
    icon_class = direction == 'desc' ? 'highest' : 'lowest'
    title = direction == 'desc' ? _('Sort direction: Descending') : _('Sort direction: Ascending')

    link_options = { action: action, direction: reversed_direction }

    render Pajamas::ButtonComponent.new(href: wiki_path(wiki, **link_options), icon: "sort-#{icon_class}", button_options: { class: link_class, title: title })
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
      'wiki-format' => page.format,
      'wiki-title-size' => page.title.bytesize,
      'wiki-content-size' => page.raw_content.bytesize,
      'wiki-directory-nest-level' => page.path.scan('/').count,
      'wiki-container-type' => page.wiki.container.class.name
    }
  end

  def show_enable_confluence_integration?(container)
    container.is_a?(Project) &&
      current_user&.can?(:admin_project, container) &&
      !container.has_confluence?
  end

  def wiki_page_render_api_endpoint(page)
    expose_path(api_v4_projects_wikis_path(wiki_page_render_api_endpoint_params(page)))
  end

  def wiki_markup_hash_by_name_id
    Wiki::VALID_USER_MARKUPS.map { |key, value| { value[:name] => key } }.reduce({}, :merge)
  end

  private

  def wiki_page_render_api_endpoint_params(page)
    { id: page.container.id, slug: ERB::Util.url_encode(page.slug), params: { version: page.version.id } }
  end

  def wiki_page_info(page, uploads_path: '')
    {
      last_commit_sha: page.last_commit_sha,
      persisted: page.persisted?,
      title: page.title,
      content: page.raw_content || '',
      format: page.format.to_s,
      uploads_path: uploads_path,
      slug: page.slug,
      path: wiki_page_path(page.wiki, page),
      wiki_path: wiki_path(page.wiki),
      help_path: help_page_path('user/project/wiki/index'),
      markdown_help_path: help_page_path('user/markdown'),
      markdown_preview_path: wiki_page_path(page.wiki, page, action: :preview_markdown),
      create_path: wiki_path(page.wiki, action: :create)
    }
  end

  def wiki_page_basic_info(page)
    {
      title: page.title,
      format: page.format.to_s,
      slug: page.slug,
      path: wiki_page_path(page.wiki, page)
    }
  end
end

WikiHelper.prepend_mod_with('WikiHelper')
