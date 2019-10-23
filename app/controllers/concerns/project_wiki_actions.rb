# frozen_string_literal: true

# Controllers that include this concern must provide:
#  * project
#  * current_user
module ProjectWikiActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_read_wiki!
    before_action :init_wiki_actions

    attr_accessor :project_wiki, :sidebar_page, :sidebar_wiki_entries
  end

  def init_wiki_actions
    load_project_wiki
    load_wiki_sidebar
  rescue ProjectWiki::CouldNotCreateWikiError
    flash[:notice] = _("Could not create Wiki Repository at this time. Please try again later.")
    redirect_to project_path(project)
  end

  def load_project_wiki
    self.project_wiki = load_wiki
  end

  def load_wiki_sidebar
    self.sidebar_page = project_wiki.find_sidebar(params[:version_id])

    return if sidebar_page.present?

    # Fallback to default sidebar
    self.sidebar_wiki_entries = WikiDirectory.group_by_directory(project_wiki.list_pages(limit: 15))
  end

  def load_wiki
    # Call #wiki to make sure the Wiki Repo is initialized
    ProjectWiki.new(project, current_user).tap(&:wiki)
  end
end
