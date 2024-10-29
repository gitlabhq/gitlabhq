# frozen_string_literal: true

class Projects::TagsController < Projects::ApplicationController
  include SortingHelper

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  before_action :authorize_admin_tag!, only: [:new, :create, :destroy]

  feature_category :source_code_management
  urgency :low, [:new, :show, :index]

  def index
    begin
      tags_params = params
        .permit(:search, :sort, :per_page, :page_token, :page)
        .with_defaults(sort: sort_value_recently_updated)

      @sort = tags_params[:sort]
      @search = tags_params[:search]

      @tags = TagsFinder.new(@repository, tags_params).execute

      @tags = Kaminari.paginate_array(@tags).page(tags_params[:page])
      tag_names = @tags.map(&:name)
      @tags_pipelines = @project.ci_pipelines.latest_successful_for_refs(tag_names)

      @releases = ReleasesFinder.new(project, current_user, tag: tag_names).execute
      @tag_pipeline_statuses = Ci::CommitStatusesFinder.new(@project, @repository, current_user, @tags).execute

    rescue Gitlab::Git::CommandError => e
      @tags = []
      @releases = []
      @tags_loading_error = e
    end

    respond_to do |format|
      status = @tags_loading_error ? :service_unavailable : :ok

      format.html { render status: status }
      format.atom { render layout: 'xml', status: status }
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @tag = @repository.find_tag(params[:id])

    return render_404 unless @tag

    @release = @project.releases.find_by(tag: @tag.name)
    @commit = @repository.commit(@tag.dereferenced_target)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def create
    # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
    evidence_pipeline = find_evidence_pipeline

    result = ::Tags::CreateService.new(@project, current_user)
      .execute(params[:tag_name], params[:ref], params[:message])

    if result[:status] == :success
      # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
      if params[:release_description].present?
        release_params = {
          tag: params[:tag_name],
          name: params[:tag_name],
          description: params[:release_description],
          evidence_pipeline: evidence_pipeline
        }

        Releases::CreateService
          .new(@project, current_user, release_params)
          .execute
      end

      @tag = result[:tag]

      redirect_to project_tag_path(@project, @tag.name)
    else
      @error = result[:message]
      @message = params[:message]
      @release_description = params[:release_description]
      render action: 'new'
    end
  end

  def destroy
    result = ::Tags::DestroyService.new(project, current_user).execute(params[:id])

    flash_type = result[:status] == :error ? :alert : :notice
    flash[flash_type] = result[:message]

    redirect_to project_tags_path(@project), status: :see_other
  end

  private

  # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
  def find_evidence_pipeline
    evidence_pipeline_sha = @project.repository.commit(params[:ref])&.sha
    return unless evidence_pipeline_sha

    @project.ci_pipelines.for_sha(evidence_pipeline_sha).last
  end
end
