# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include ProjectWikiActions
  include WikiHelper

  def self.local_prefixes
    [controller_path, 'shared/wiki']
  end

  def pages
    @nesting = show_children_param
    @show_children = @nesting != ProjectWiki::NESTING_CLOSED
    @wiki_pages = Kaminari.paginate_array(
      project_wiki.list_pages(**sort_params)
    ).page(params[:page])

    @wiki_entries = case @nesting
                    when ProjectWiki::NESTING_FLAT
                      @wiki_pages
                    else
                      WikiDirectory.group_by_directory(@wiki_pages)
                    end

    render 'show'
  end

  def git_access
  end

  private

  def sort_params
    process_params(sort_params_config)
  end

  def show_children_param
    config = nesting_params_config(params[:sort])

    process_params(config)
  end
end
