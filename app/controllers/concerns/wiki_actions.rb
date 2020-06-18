# frozen_string_literal: true

module WikiActions
  include SendsBlob
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  included do
    before_action :authorize_read_wiki!
    before_action :authorize_create_wiki!, only: [:edit, :create]
    before_action :authorize_admin_wiki!, only: :destroy

    before_action :wiki
    before_action :page, only: [:show, :edit, :update, :history, :destroy]
    before_action :load_sidebar, except: [:pages]

    before_action only: [:show, :edit, :update] do
      @valid_encoding = valid_encoding?
    end

    before_action only: [:edit, :update], unless: :valid_encoding? do
      redirect_to wiki_page_path(wiki, page)
    end
  end

  def new
    redirect_to wiki_page_path(wiki, SecureRandom.uuid, random_title: true)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def pages
    @wiki_pages = Kaminari.paginate_array(
      wiki.list_pages(sort: params[:sort], direction: params[:direction])
    ).page(params[:page])

    @wiki_entries = WikiPage.group_by_directory(@wiki_pages)

    render 'shared/wikis/pages'
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # `#show` handles a number of scenarios:
  #
  # - If `id` matches a WikiPage, then show the wiki page.
  # - If `id` is a file in the wiki repository, then send the file.
  # - If we know the user wants to create a new page with the given `id`,
  #   then display a create form.
  # - Otherwise show the empty wiki page and invite the user to create a page.
  #
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def show
    if page
      set_encoding_error unless valid_encoding?

      # Assign vars expected by MarkupHelper
      @ref = params[:version_id]
      @path = page.path

      render 'shared/wikis/show'
    elsif file_blob
      send_blob(wiki.repository, file_blob, allow_caching: container.public?)
    elsif show_create_form?
      # Assign a title to the WikiPage unless `id` is a randomly generated slug from #new
      title = params[:id] unless params[:random_title].present?

      @page = build_page(title: title)

      render 'shared/wikis/edit'
    else
      render 'shared/wikis/empty'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def edit
    render 'shared/wikis/edit'
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def update
    return render('shared/wikis/empty') unless can?(current_user, :create_wiki, container)

    @page = WikiPages::UpdateService.new(container: container, current_user: current_user, params: wiki_params).execute(page)

    if page.valid?
      redirect_to(
        wiki_page_path(wiki, page),
        notice: _('Wiki was successfully updated.')
      )
    else
      render 'shared/wikis/edit'
    end
  rescue WikiPage::PageChangedError, WikiPage::PageRenameError, Gitlab::Git::Wiki::OperationError => e
    @error = e
    render 'shared/wikis/edit'
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def create
    @page = WikiPages::CreateService.new(container: container, current_user: current_user, params: wiki_params).execute

    if page.persisted?
      redirect_to(
        wiki_page_path(wiki, page),
        notice: _('Wiki was successfully updated.')
      )
    else
      render 'shared/wikis/edit'
    end
  rescue Gitlab::Git::Wiki::OperationError => e
    @page = build_page(wiki_params)
    @error = e
    render 'shared/wikis/edit'
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def history
    if page
      @page_versions = Kaminari.paginate_array(page.versions(page: params[:page].to_i),
                                               total_count: page.count_versions)
        .page(params[:page])

      render 'shared/wikis/history'
    else
      redirect_to(
        wiki_path(wiki),
        notice: _("Page not found")
      )
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def destroy
    WikiPages::DestroyService.new(container: container, current_user: current_user).execute(page)

    redirect_to wiki_path(wiki),
                status: :found,
                notice: _("Page was successfully deleted")
  rescue Gitlab::Git::Wiki::OperationError => e
    @error = e
    render 'shared/wikis/edit'
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def container
    raise NotImplementedError
  end

  def show_create_form?
    can?(current_user, :create_wiki, container) &&
      page.nil? &&
      # Always show the create form when the wiki has had at least one page created.
      # Otherwise, we only show the form when the user has navigated from
      # the 'empty wiki' page
      (wiki.exists? || params[:view] == 'create')
  end

  def wiki
    strong_memoize(:wiki) do
      wiki = Wiki.for_container(container, current_user)

      # Call #wiki to make sure the Wiki Repo is initialized
      wiki.wiki

      wiki
    end
  rescue Wiki::CouldNotCreateWikiError
    flash[:notice] = _("Could not create Wiki Repository at this time. Please try again later.")
    redirect_to container
    false
  end

  def page
    strong_memoize(:page) do
      wiki.find_page(*page_params)
    end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def load_sidebar
    @sidebar_page = wiki.find_sidebar(params[:version_id])

    unless @sidebar_page # Fallback to default sidebar
      @sidebar_wiki_entries, @sidebar_limited = wiki.sidebar_entries
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def wiki_params
    params.require(:wiki).permit(:title, :content, :format, :message, :last_commit_sha)
  end

  def build_page(args = {})
    WikiPage.new(wiki).tap do |page|
      page.update_attributes(args) # rubocop:disable Rails/ActiveRecordAliases
    end
  end

  def page_params
    keys = [:id]
    keys << :version_id if params[:action] == 'show'

    params.values_at(*keys)
  end

  def valid_encoding?
    page_encoding == Encoding::UTF_8
  end

  def page_encoding
    strong_memoize(:page_encoding) { page&.content&.encoding }
  end

  def set_encoding_error
    flash.now[:notice] = _("The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.")
  end

  def file_blob
    strong_memoize(:file_blob) do
      commit = wiki.repository.commit(wiki.default_branch)

      next unless commit

      wiki.repository.blob_at(commit.id, params[:id])
    end
  end
end
