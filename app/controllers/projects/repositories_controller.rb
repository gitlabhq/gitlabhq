# frozen_string_literal: true

class Projects::RepositoriesController < Projects::ApplicationController
  include ExtractsPath
  include StaticObjectExternalStorage
  include Gitlab::RateLimitHelpers
  include HotlinkInterceptor

  prepend_before_action(only: [:archive]) { authenticate_sessionless_user!(:archive) }

  skip_before_action :default_cache_headers, only: :archive

  # Authorize
  before_action :require_non_empty_project, except: :create
  before_action :archive_rate_limit!, only: :archive
  before_action :intercept_hotlinking!, only: :archive
  before_action :assign_archive_vars, only: :archive
  before_action :assign_append_sha, only: :archive
  before_action :authorize_download_code!
  before_action :authorize_admin_project!, only: :create
  before_action :redirect_to_external_storage, only: :archive, if: :static_objects_external_storage_enabled?

  feature_category :source_code_management

  def create
    @project.create_repository

    redirect_to project_path(@project)
  end

  def archive
    return render_404 if html_request?

    set_cache_headers
    return if archive_not_modified?

    send_git_archive @repository, **repo_params
  rescue StandardError => ex
    logger.error("#{self.class.name}: #{ex}")
    git_not_found!
  end

  private

  def archive_rate_limit!
    if archive_rate_limit_reached?(current_user, @project)
      render plain: ::Gitlab::RateLimitHelpers::ARCHIVE_RATE_LIMIT_REACHED_MESSAGE, status: :too_many_requests
    end
  end

  def repo_params
    @repo_params ||= { ref: @ref, path: params[:path], format: params[:format], append_sha: @append_sha }
  end

  def set_cache_headers
    expires_in cache_max_age(archive_metadata['CommitId']), public: Guest.can?(:download_code, project)
    fresh_when(etag: archive_metadata['ArchivePath'])
  end

  def archive_not_modified?
    # Check response freshness (Last-Modified and ETag)
    # against request If-Modified-Since and If-None-Match conditions.
    request.fresh?(response)
  end

  def archive_metadata
    @archive_metadata ||= @repository.archive_metadata(
      @ref,
      '', # Where archives are stored isn't really important for ETag purposes
      repo_params[:format],
      path: repo_params[:path],
      append_sha: @append_sha
    )
  end

  def cache_max_age(commit_id)
    if @ref == commit_id
      # This is a link to an archive by a commit SHA. That means that the archive
      # is immutable. The only reason to invalidate the cache is if the commit
      # was deleted or if the user lost access to the repository.
      Repository::ARCHIVE_CACHE_TIME_IMMUTABLE
    else
      # A branch or tag points at this archive. That means that the expected archive
      # content may change over time.
      Repository::ARCHIVE_CACHE_TIME
    end
  end

  def assign_append_sha
    @append_sha = params[:append_sha]

    if @ref
      shortname = "#{@project.path}-#{@ref.tr('/', '-')}"
      @append_sha = false if @filename == shortname
    end
  end

  def assign_archive_vars
    if params[:id]
      @ref, @filename = extract_ref_and_filename(params[:id])
    else
      @ref = params[:ref]
      @filename = nil
    end
  rescue InvalidPathError
    render_404
  end

  # path can be of the form:
  # master
  # master/first.zip
  # master/first/second.tar.gz
  # master/first/second/third.zip
  #
  # In the archive case, we know that the last value is always the filename, so we
  # do a greedy match to extract the ref. This avoid having to pull all ref names
  # from Redis.
  def extract_ref_and_filename(id)
    path = id.strip
    data = path.match(%r{(.*)/(.*)})

    if data
      [data[1], data[2]]
    else
      [path, nil]
    end
  end
end

Projects::RepositoriesController.prepend_mod_with('Projects::RepositoriesController')
