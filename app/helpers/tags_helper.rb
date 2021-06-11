# frozen_string_literal: true

module TagsHelper
  def tag_path(tag)
    "/tags/#{tag}"
  end

  def filter_tags_path(options = {})
    exist_opts = {
      search: params[:search],
      sort: params[:sort]
    }

    options = exist_opts.merge(options)
    project_tags_path(@project, @id, options)
  end

  def protected_tag?(project, tag)
    ProtectedTag.protected?(project, tag.name)
  end

  def tag_description_help_text
    text = s_('TagsPage|Optionally, add a message to the tag. Leaving this blank creates '\
              'a %{link_start}lightweight tag.%{link_end}') % {
      link_start: '<a href="https://git-scm.com/book/en/v2/Git-Basics-Tagging\" target="_blank" rel="noopener noreferrer">',
      link_end: '</a>'
    }

    text.html_safe
  end

  def delete_tag_modal_attributes(tag_name)
    {
      title: s_('TagsPage|Delete tag'),
      message: s_('TagsPage|Deleting the %{tag_name} tag cannot be undone. Are you sure?') % { tag_name: tag_name },
      okVariant: 'danger',
      okTitle: s_('TagsPage|Delete tag')
    }.to_json
  end
end
