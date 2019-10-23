# frozen_string_literal: true

class Projects::WikiPagesController < Projects::ApplicationController
  include ProjectWikiActions
  include SendsBlob
  include PreviewMarkdown
  include Gitlab::Utils::StrongMemoize

  def self.local_prefixes
    [controller_path, 'shared/wiki']
  end

  before_action :authorize_create_wiki!, only: [:edit, :create, :update]
  before_action :authorize_admin_wiki!, only: :destroy

  before_action :load_page, only: [:show, :edit, :update, :history, :destroy]
  before_action :valid_encoding?,
    if: -> { %w[show edit update].include?(action_name) && load_page }
  before_action only: [:edit, :update], unless: :valid_encoding? do
    redirect_to(project_wiki_path(@project, @page))
  end

  def new
    redirect_to project_wiki_path(@project, SecureRandom.uuid, random_title: true)
  end

  # `#show` handles a number of scenarios:
  #
  # - If `id` matches a WikiPage, then show the wiki page.
  # - If `id` is a file in the wiki repository, then send the file.
  # - If we know the user wants to create a new page with the given `id`,
  #   then display a create form.
  # - Otherwise show the empty wiki page and invite the user to create a page.
  def show
    if @page
      show_page
    elsif file_blob
      show_blob
    elsif should_create_missing_page?
      create_missing_page
    else
      render 'missing_page'
    end
  end

  def edit
  end

  def update
    @page = WikiPages::UpdateService
      .new(@project, current_user, wiki_params)
      .execute(@page)

    return saved(:updated) if @page.valid?

    render 'edit'
  rescue WikiPage::PageChangedError, WikiPage::PageRenameError, Gitlab::Git::Wiki::OperationError => e
    @error = e
    render 'edit'
  end

  def create
    @page = WikiPages::CreateService
      .new(@project, current_user, wiki_params)
      .execute

    return saved(:created) if @page.persisted?

    render action: "edit"
  rescue Gitlab::Git::Wiki::OperationError => e
    @page = project_wiki.build_page(wiki_params)
    @error = e

    render 'edit'
  end

  def history
    if @page
      @page_versions = Kaminari.paginate_array(@page.versions(page: params[:page].to_i),
                                               total_count: @page.count_versions)
        .page(params[:page])
    else
      redirect_to(
        project_wiki_path(@project, :home),
        notice: _("Page not found")
      )
    end
  end

  def destroy
    WikiPages::DestroyService.new(@project, current_user).execute(@page)

    redirect_to project_wiki_path(@project, :home),
                status: 302,
                notice: _("Page was successfully deleted")
  rescue Gitlab::Git::Wiki::OperationError => e
    @error = e
    render 'edit'
  end

  private

  # Callback for PreviewMarkdown
  def preview_markdown_params
    { pipeline: :wiki, project_wiki: project_wiki, page_slug: params[:id] }
  end

  def show_page
    set_encoding_error unless valid_encoding?

    @page_dir = @project_wiki.find_dir(@page.directory) if @page.directory.present?
    @show_children = true

    render 'show'
  end

  def show_blob
    send_blob(@project_wiki.repository, file_blob)
  end

  def should_create_missing_page?
    view_param = @project_wiki.exists? ? 'create' : params[:view]
    view_param == 'create' && can?(current_user, :create_wiki, @project)
  end

  def create_missing_page
    # Assign a title to the WikiPage unless `id` is a randomly generated slug from #new
    title = params[:id] unless params[:random_title].present?

    @page = project_wiki.build_page(title: title)

    render 'edit'
  end

  def wiki_params
    params.require(:wiki_page).permit(:title, :content, :format, :message, :last_commit_sha)
  end

  def load_page
    @page ||= @project_wiki.find_page(*page_params)
  end

  def page_params
    keys = [:id]
    keys << :version_id if params[:action] == 'show'

    params.values_at(*keys)
  end

  def valid_encoding?
    strong_memoize(:valid_encoding) do
      @page.content.encoding == Encoding::UTF_8
    end
  end

  def set_encoding_error
    flash.now[:notice] = _("The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.")
  end

  def file_blob
    strong_memoize(:file_blob) do
      commit = @project_wiki.repository.commit(@project_wiki.default_branch)

      next unless commit

      @project_wiki.repository.blob_at(commit.id, params[:id])
    end
  end

  def saved(action)
    msg = case action
          when :updated
            _('Wiki was successfully updated')
          when :created
            _('Wiki was successfully created')
          end

    redirect_to(project_wiki_path(@project, @page), notice: msg)
  end
end
