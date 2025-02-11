# frozen_string_literal: true

module WikiActions
  include DiffHelper
  include PreviewMarkdown
  include SendsBlob
  include Gitlab::Utils::StrongMemoize
  include ProductAnalyticsTracking
  include SafeFormatHelper
  extend ActiveSupport::Concern
  include StrongPaginationParams

  RESCUE_GIT_TIMEOUTS_IN = %w[show raw edit history diff pages templates].freeze

  included do
    content_security_policy do |p|
      next if p.directives.blank?
      next unless Gitlab::CurrentSettings.diagramsnet_enabled?

      default_frame_src = p.directives['frame-src'] || p.directives['default-src']
      frame_src_values = Array.wrap(default_frame_src) | [Gitlab::CurrentSettings.diagramsnet_url].compact

      p.frame_src(*frame_src_values)
    end

    before_action { respond_to :html }

    before_action :authorize_read_wiki!
    before_action :authorize_create_wiki!, only: [:edit, :create, :destroy]

    before_action :wiki
    before_action :page, only: [:show, :edit, :update, :history, :destroy, :diff]
    before_action :load_sidebar, except: [:pages]

    before_action do
      push_frontend_feature_flag(:preserve_markdown, container)
      push_force_frontend_feature_flag(:glql_integration, container&.glql_integration_feature_flag_enabled?)
      push_force_frontend_feature_flag(:continue_indented_text, container&.continue_indented_text_feature_flag_enabled?)
    end

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

    track_internal_event :show, name: 'view_wiki_page'

    helper_method :view_file_button, :diff_file_html_data

    rescue_from ::Gitlab::Git::CommandTimedOut do |exc|
      raise exc unless RESCUE_GIT_TIMEOUTS_IN.include?(action_name)

      render 'shared/wikis/git_error'
    end

    rescue_from Gitlab::Git::Repository::NoRepository do
      @error = s_('Wiki|Could not access the Wiki Repository at this time.')

      render 'shared/wikis/empty'
    end
  end

  def new
    redirect_to wiki_page_path(wiki, SecureRandom.uuid, random_title: true)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def pages
    @wiki_entries = WikiDirectory.group_pages(pages_list)

    render 'shared/wikis/pages'
  end

  def pages_list
    strong_memoize(:pages_list) do
      Kaminari.paginate_array(
        # only include pages not starting with 'templates/'
        wiki
          .list_pages(direction: params[:direction])
          .reject { |page| page.slug.start_with?('templates/') }
      ).page(pagination_params[:page])
    end
  end

  def templates_list
    strong_memoize(:templates_list) do
      Kaminari.paginate_array(
        # only include pages starting with 'templates/'
        wiki
          .list_pages(direction: params[:direction])
          .select { |page| page.slug.start_with?('templates/') }
      ).page(pagination_params[:page])
    end
  end

  def templates
    @wiki_entries_count = templates_list.total_count
    @wiki_entries = WikiDirectory.group_pages(templates_list, templates: true)

    render 'shared/wikis/templates'
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
      @templates = templates_list

      render 'shared/wikis/show'
    elsif file_blob
      # This is needed by [GitLab JH](https://gitlab.com/gitlab-jh/gitlab/-/issues/247)
      send_wiki_file_blob(wiki, file_blob)
    else
      handle_redirection
    end
  end

  def handle_redirection
    redir = find_redirection(params[:id]) unless params[:redirect_limit_reached] || params[:no_redirect]
    if redir.is_a?(Hash) && redir[:error]
      message = safe_format(
        s_('Wiki|The page at %{code_start}%{redirected_from}%{code_end} redirected too many times. ' \
          'You are now editing the page at %{code_start}%{redirected_from}%{code_end}.'),
        tag_pair(helpers.content_tag(:code), :code_start, :code_end),
        redirected_from: params[:id]
      )
      redirect_to(
        "#{wiki_page_path(wiki, params[:id])}?redirect_limit_reached=true",
        status: :found,
        notice: message
      )
    elsif redir
      redirected_from = params[:redirected_from] || params[:id]
      message = safe_format(
        s_('Wiki|The page at %{code_start}%{redirected_from}%{code_end} ' \
          'has been moved to %{code_start}%{redirected_to}%{code_end}.'),
        tag_pair(helpers.content_tag(:code), :code_start, :code_end),
        redirected_from: redirected_from,
        redirected_to: redir
      )
      redirect_to(
        "#{wiki_page_path(wiki, redir)}?redirected_from=#{redirected_from}",
        status: :found,
        notice: message
      )
    elsif show_create_form?
      handle_create_form
    elsif wiki.exists?
      render 'shared/wikis/404', status: :not_found
    else
      render 'shared/wikis/empty'
    end
  end

  def handle_create_form
    title = params[:id]
    if params[:redirected_from] # override the notice if redirected
      redirected_link = helpers.link_to('', "#{wiki_page_path(wiki, params[:redirected_from])}?no_redirect=true")
      flash[:notice] = safe_format(
        s_('Wiki|The page at %{code_start}%{redirected_from}%{code_end} tried to redirect to ' \
          '%{code_start}%{redirected_to}%{code_end}, but it does not exist. You are now ' \
          'editing the page at %{code_start}%{redirected_to}%{code_end}. %{link_start}Edit ' \
          'page at %{code_start}%{redirected_from}%{code_end} instead.%{link_end}'
          ),
        tag_pair(helpers.content_tag(:code), :code_start, :code_end),
        tag_pair(redirected_link, :link_start, :link_end),
        redirected_from: params[:redirected_from],
        redirected_to: params[:id]
      )
    end

    @page = build_page(title: title)
    @templates = templates_list

    render 'shared/wikis/edit'

    flash[:notice] = nil if params[:redirected_from]
  end

  def raw
    response.headers['Content-Type'] = 'text/plain'
    render plain: page.raw_content
  end

  def edit
    @templates = templates_list

    render 'shared/wikis/edit'
  end

  def update
    return render('shared/wikis/empty') unless can?(current_user, :create_wiki, container)

    response = WikiPages::UpdateService.new(
      container: container,
      current_user: current_user,
      params: wiki_params
    ).execute(page)
    @page = response.payload[:page]

    if response.success?
      handle_action_success :updated, @page
    else
      @error = response.message
      @templates = templates_list

      render 'shared/wikis/edit'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def create
    response = WikiPages::CreateService.new(container: container, current_user: current_user,
      params: wiki_params).execute
    @page = response.payload[:page]

    if response.success?
      handle_action_success :created, @page
    else
      @templates = templates_list

      render 'shared/wikis/edit'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def history
    if page
      @commits_count = page.count_versions
      @commits = Kaminari.paginate_array(page.versions(page: pagination_params[:page].to_i),
        total_count: page.count_versions)
        .page(pagination_params[:page])

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
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def destroy
    return render_404 unless page

    response = WikiPages::DestroyService.new(container: container, current_user: current_user).execute(page)

    if response.success?
      flash[:toast] = _("Wiki page was successfully deleted.")

      redirect_to wiki_path(wiki), status: :found
    else
      @error = response.message
      @templates = templates_list

      render 'shared/wikis/edit'
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def git_access
    render 'shared/wikis/git_access'
  end

  private

  def handle_action_success(action, page)
    if page.title == Wiki::SIDEBAR
      flash[:toast] = s_('Wiki|Sidebar was successfully created.') if action == :created
      flash[:toast] = s_('Wiki|Sidebar was successfully updated.') if action == :updated

      redirect_to wiki_path(wiki)
    else
      flash[:toast] = s_('Wiki|Wiki page was successfully created.') if action == :created
      flash[:toast] = s_('Wiki|Wiki page was successfully updated.') if action == :updated

      redirect_to(wiki_page_path(wiki, page))
    end
  end

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
      wiki.create_wiki_repository

      wiki
    end
  rescue Wiki::CouldNotCreateWikiError
    flash[:notice] = _("Could not create Wiki Repository at this time. Please try again later.")
    redirect_to container
    false
  end

  def page
    strong_memoize(:page) do
      wiki.find_page(*page_params, load_content: load_content?)
    end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def load_sidebar
    @sidebar_page = wiki.find_sidebar(params[:version_id])
    @wiki_pages_count = pages_list.total_count
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
    flash.now[:notice] =
      _("The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.")
  end

  def file_blob
    strong_memoize(:file_blob) do
      commit = wiki.repository.commit(wiki.default_branch)

      next unless commit

      wiki.repository.blob_at(commit.id, params[:id])
    end
  end

  # Override CommitsHelper#view_file_button
  def view_file_button(commit_sha, *args)
    path = wiki_page_path(wiki, page, version_id: page.version.id)

    helpers.link_button_to(path) do
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

  def send_wiki_file_blob(wiki, file_blob)
    send_blob(wiki.repository, file_blob)
  end

  def load_content?
    skip_actions = %w[history destroy diff]

    return false if skip_actions.include?(params[:action])

    true
  end

  def tracking_project_source
    container if container.is_a?(Project)
  end

  def tracking_namespace_source
    case container
    when Project
      container.namespace
    when Group
      container
    end
  end

  def find_redirection(path, redirect_limit = 50)
    seen = Set[]
    current_path = path

    redirect_limit.times do
      seen << current_path
      next_path = find_single_redirection(current_path)

      # if no single redirect is found, then use the current path
      # unless it is the same as the original path
      return current_path == path ? nil : current_path if next_path.nil?

      # if the file was already seen, then we have a loop
      return { error: true, reason: :loop } if seen.include?(next_path)

      current_path = next_path
    end

    { error: true, reason: :limit }
  end

  def find_single_redirection(path)
    current = path
    rest = []

    until current == '.'
      redirect = redirections[current]
      return File.join(redirect, *rest) if redirect

      current, basename = File.split(current)
      rest.unshift(basename)
    end

    nil
  end

  def redirections
    strong_memoize(:redirections) do
      redirects_file = wiki.repository.blob_at(wiki.default_branch, Wiki::REDIRECTS_YML, limit: 0.5.megabytes)
      redirects_file ? YAML.safe_load(redirects_file.data).to_h : {}
    end
  end
end

WikiActions.prepend_mod
