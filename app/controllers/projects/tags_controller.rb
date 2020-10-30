# frozen_string_literal: true

class Projects::TagsController < Projects::ApplicationController
  include SortingHelper

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_admin_tag!, only: [:new, :create, :destroy]

  feature_category :source_code_management, [:index, :show, :new, :destroy]
  feature_category :release_evidence, [:create]

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    params[:sort] = params[:sort].presence || sort_value_recently_updated

    @sort = params[:sort]
    @tags = TagsFinder.new(@repository, params).execute
    @tags = Kaminari.paginate_array(@tags).page(params[:page])

    tag_names = @tags.map(&:name)
    @tags_pipelines = @project.ci_pipelines.latest_successful_for_refs(tag_names)
    @releases = project.releases.where(tag: tag_names)
    @tag_pipeline_statuses = Ci::CommitStatusesFinder.new(@project, @repository, current_user, @tags).execute

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml.atom' }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @tag = @repository.find_tag(params[:id])

    return render_404 unless @tag

    @release = @project.releases.find_or_initialize_by(tag: @tag.name)
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

    if result[:status] == :success
      render json: result
    else
      render json: { message: result[:message] }, status: result[:return_code]
    end
  end

  private

  # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
  def find_evidence_pipeline
    evidence_pipeline_sha = @project.repository.commit(params[:ref])&.sha
    return unless evidence_pipeline_sha

    @project.ci_pipelines.for_sha(evidence_pipeline_sha).last
  end
end
