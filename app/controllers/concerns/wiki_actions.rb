# frozen_string_literal: true

module WikiActions
  include DiffHelper
  include PreviewMarkdown
  include SendsBlob
  include Gitlab::Utils::StrongMemoize
  include RedisTracking
  extend ActiveSupport::Concern

  RESCUE_GIT_TIMEOUTS_IN = %w[show edit history diff pages].freeze

  included do
    before_action { respond_to :html }

    before_action :authorize_read_wiki!
    before_action :authorize_create_wiki!, only: [:edit, :create, :destroy]

    before_action :wiki
    before_action :page, only: [:show, :edit, :update, :history, :destroy, :diff]
    before_action :load_sidebar, except: [:pages]
    before_action :set_content_class

    before_action only: [:show, :edit, :update] do
      @valid_encoding = valid_encoding?
    end

    before_action only: [:edit, :update], unless: :valid_encoding? do
      if params[:id].present?
        redirect_to wiki_page_path(wiki, page || params[:id])
      else
        redirect_to wiki_path(wiki)
      end
    end

    # NOTE: We want to include wiki page views in the same counter as the other
    # Event-based wiki actions tracked through TrackUniqueEvents, so we use the same event name.
    track_redis_hll_event :show, name: Gitlab::UsageDataCounters::TrackUniqueEvents::WIKI_ACTION.to_s

    helper_method :view_file_button, :diff_file_html_data

    rescue_from ::Gitlab::Git::CommandTimedOut do |exc|
      raise exc unless RESCUE_GIT_TIMEOUTS_IN.include?(action_name)

      render 'shared/wikis/git_error'
    end
  end

  def new
    redirect_to wiki_page_path(wiki, SecureRandom.uuid, random_title: true)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def pages
    @wiki_entries = WikiDirectory.group_pages(wiki_pages)

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

      Gitlab::UsageDataCounters::WikiPageCounter.count(:view)

      render 'shared/wikis/show'
    elsif file_blob
      send_blob(wiki.repository, file_blob)
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

    response = WikiPages::UpdateService.new(container: container, current_user: current_user, params: wiki_params).execute(page)
    @page = response.payload[:page]

    if response.success?
      flash[:toast] = _('Wiki page was successfully updated.')

      redirect_to(
        wiki_page_path(wiki, page)
      )
    else
      @error = response.message
      render 'shared/wikis/edit'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def create
    response = WikiPages::CreateService.new(container: container, current_user: current_user, params: wiki_params).execute
    @page = response.payload[:page]

    if response.success?
      flash[:toast] = _('Wiki page was successfully created.')

      redirect_to(
        wiki_page_path(wiki, page)
      )
    else
      render 'shared/wikis/edit'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def history
    if page
      @commits = Kaminari.paginate_array(page.versions(page: params[:page].to_i),
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
  def diff
    return render_404 unless page

    apply_diff_view_cookie!

    @diffs = page.diffs(diff_options)
    @diff_notes_disabled = true

    render 'shared/wikis/diff'
  end
  # rubocop:disable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def destroy
    return render_404 unless page

    response = WikiPages::DestroyService.new(container: container, current_user: current_user).execute(page)

    if response.success?
      flash[:toast] = _("Wiki page was successfully deleted.")

      redirect_to wiki_path(wiki),
      status: :found
    else
      @error = response.message
      render 'shared/wikis/edit'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def git_access
    render 'shared/wikis/git_access'
  end

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
  rescue ::Gitlab::Git::CommandTimedOut => e
    @sidebar_error = e
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def wiki_pages
    strong_memoize(:wiki_pages) do
      Kaminari.paginate_array(
        wiki.list_pages(sort: params[:sort], direction: params[:direction])
      ).page(params[:page])
    end
  end

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
    keys << :version_id if %w[show diff].include?(params[:action])

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

  def set_content_class
    @content_class = 'limit-container-width' unless fluid_layout # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  # Override CommitsHelper#view_file_button
  def view_file_button(commit_sha, *args)
    path = wiki_page_path(wiki, page, version_id: page.version.id)

    helpers.link_to(path, class: 'btn') do
      helpers.raw(_('View page @ ')) + helpers.content_tag(:span, Commit.truncate_sha(commit_sha), class: 'commit-sha')
    end
  end

  # Override DiffHelper#diff_file_html_data
  def diff_file_html_data(_project, _diff_file_path, diff_commit_id)
    {
      blob_diff_path: wiki_page_path(wiki, page, action: :diff, version_id: diff_commit_id),
      view: diff_view
    }
  end
end
