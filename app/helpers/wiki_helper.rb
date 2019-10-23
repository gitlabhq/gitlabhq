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

  def wiki_attachment_upload_url
    expose_url(api_v4_projects_wikis_attachments_path(id: @project.id))
  end

  WIKI_SORT_CSS_CLASSES = 'btn btn-default has-tooltip reverse-sort-btn qa-reverse-sort rspec-reverse-sort'

  def wiki_sort_controls(sort_params = {}, &block)
    current_sort = sort_params[:sort] || ProjectWiki::TITLE_ORDER
    current_direction = (sort_params[:direction] || 'asc').inquiry

    reversed_direction = current_direction.desc? ? 'asc' : 'desc'
    icon_class = current_direction.desc? ? 'highest' : 'lowest'

    sorting = sort_params.merge(sort: current_sort, direction: reversed_direction)
    opts = {
      type: 'button',
      class: WIKI_SORT_CSS_CLASSES,
      title: _('Sort direction')
    }

    link_to(yield(sorting), opts) do
      sprite_icon("sort-#{icon_class}", size: 16)
    end
  end

  def wiki_sort_title(key)
    if key == ProjectWiki::CREATED_AT_ORDER
      s_("Wiki|Created date")
    else
      s_("Wiki|Title")
    end
  end

  # Render the sprite icon given the current show_children state
  def wiki_show_children_icon(nesting)
    icon_name, icon_text =
      case nesting
      when ProjectWiki::NESTING_TREE
        ['folder-open', s_("Wiki|Show folder contents")]
      when ProjectWiki::NESTING_CLOSED
        ['folder-o', s_("Wiki|Hide folder contents")]
      else
        ['list-bulleted', s_("Wiki|Show files separately")]
      end

    sprite_icon_with_text(icon_name, icon_text, size: 16)
  end

  def wiki_page_link(wiki_page, nesting, project)
    link = link_to(wiki_page.title,
                   project_wiki_path(project, wiki_page),
                   class: 'wiki-page-title')

    case nesting
    when ProjectWiki::NESTING_FLAT
      tags = []
      if wiki_page.directory.present?
        wiki_dir = WikiDirectory.new(wiki_page.directory)
        tags << link_to(wiki_dir.slug, project_wiki_dir_path(project, wiki_dir), class: 'wiki-page-dir-name')
        tags << content_tag(:span, '/', class: 'wiki-page-name-separator')
      end

      tags << link
      tags.join.html_safe
    else
      link
    end
  end

  def sort_params_config
    {
      keys: [:sort, :direction],
      defaults: {
        sort: ProjectWiki::TITLE_ORDER, direction: ProjectWiki::DIRECTION_ASC
      },
      allowed: {
        sort: ProjectWiki::SORT_ORDERS, direction: ProjectWiki::SORT_DIRECTIONS
      }
    }
  end

  def nesting_params_config(sort_key)
    default_val = case sort_key
                  when ProjectWiki::CREATED_AT_ORDER
                    ProjectWiki::NESTING_FLAT
                  else
                    ProjectWiki::NESTING_CLOSED
                  end
    {
      keys: [:show_children],
      defaults: { show_children: default_val },
      allowed: { show_children: ProjectWiki::NESTINGS }
    }
  end

  def process_params(config)
    unprocessed = params.permit(*config[:keys])

    processed = unprocessed
      .with_defaults(config[:defaults])
      .tap { |h| Gitlab::Utils.allow_hash_values(h, config[:allowed]) }
      .to_hash
      .transform_keys(&:to_sym)

    if processed.keys == config[:keys]
      processed.size == 1 ? processed.values.first : processed
    else
      raise ActionController::BadRequest, "illegal parameters: #{unprocessed}"
    end
  end

  def home_page?
    params[:id] == 'home'
  end
end
