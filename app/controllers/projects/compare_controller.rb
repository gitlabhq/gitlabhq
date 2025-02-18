# frozen_string_literal: true

require 'addressable/uri'

class Projects::CompareController < Projects::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersCommits
  include CompareHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  # Defining ivars
  before_action :define_diffs, only: [:show, :diff_for_path, :rapid_diffs]
  before_action :define_environment, only: [:show, :rapid_diffs]
  before_action :define_diff_notes_disabled, only: [:show, :diff_for_path, :rapid_diffs]
  before_action :define_commits, only: [:show, :diff_for_path, :signatures, :rapid_diffs]
  before_action :merge_request, only: [:index, :show, :rapid_diffs]
  # Validation
  before_action :validate_refs!

  feature_category :source_code_management
  urgency :low, [:show, :create, :signatures]

  # Diffs may be pretty chunky, the less is better in this endpoint.
  # Pagination design guides: https://design.gitlab.com/components/pagination/#behavior
  COMMIT_DIFFS_PER_PAGE = 20

  def index
    compare_params
  end

  def show
    apply_diff_view_cookie!

    respond_to do |format|
      format.html do
        render locals: { pagination_params: params.permit(:page) }
      end
    end
  end

  def diff_for_path
    return render_404 unless compare

    render_diff_for_path(compare.diffs(diff_options))
  end

  def create
    from_to_vars = build_from_to_vars

    if from_to_vars[:from].blank? || from_to_vars[:to].blank?
      flash[:alert] = "You must select a Source and a Target revision"

      redirect_to project_compare_index_path(source_project, from_to_vars)
    elsif compare_params[:straight] == "true"
      redirect_to project_compare_with_two_dots_path(source_project, from_to_vars)
    else
      redirect_to project_compare_path(source_project, from_to_vars)
    end
  end

  def signatures
    respond_to do |format|
      format.json do
        render json: {
          signatures: @commits.select(&:has_signature?).map do |commit|
            {
              commit_sha: commit.sha,
              html: view_to_html_string('projects/commit/_signature', signature: commit.signature)
            }
          end
        }
      end
    end
  end

  def rapid_diffs
    return render_404 unless ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)

    show
  end

  private

  def build_from_to_vars
    {
      from: compare_params[:from].presence,
      to: compare_params[:to].presence,
      from_project_id: compare_params[:from_project_id].presence
    }
  end

  def validate_refs!
    invalid = [head_ref, start_ref].filter { |ref| !valid_ref?(ref) }

    return if invalid.empty?

    flash[:alert] = "Invalid branch name(s): #{invalid.join(', ')}"
    redirect_to project_compare_index_path(source_project)
  end

  # target == start_ref == from
  def target_project
    strong_memoize(:target_project) do
      target_project =
        if !compare_params.key?(:from_project_id)
          source_project.default_merge_request_target
        elsif compare_params[:from_project_id].to_i == source_project.id
          source_project
        else
          target_projects(source_project).find_by_id(compare_params[:from_project_id])
        end

      # Just ignore the field if it points at a non-existent or hidden project
      next source_project unless target_project && can?(current_user, :read_code, target_project)

      target_project
    end
  end

  # source == head_ref == to
  def source_project
    strong_memoize(:source_project) do
      # Eager load project's avatar url to prevent batch loading
      # for all forked projects
      project&.tap(&:avatar_url)
    end
  end

  def compare
    return @compare if defined?(@compare)

    @compare = CompareService.new(source_project, head_ref).execute(target_project, start_ref, straight: straight)
  end

  def straight
    compare_params[:straight] == "true"
  end

  def start_ref
    @start_ref ||= Addressable::URI.unescape(compare_params[:from]).presence
  end

  def head_ref
    return @ref if defined?(@ref)

    @ref = @head_ref = Addressable::URI.unescape(compare_params[:to]).presence
  end

  def define_commits
    strong_memoize(:commits) do
      if compare.present?
        commits = compare.commits.with_markdown_cache.with_latest_pipeline(head_ref)
        set_commits_for_rendering(commits)
      else
        []
      end
    end
  end

  def define_diffs
    @diffs = compare.present? ? compare.diffs(diff_options) : []
  end

  def define_environment
    if compare
      environment_params = if source_project.repository.branch_exists?(head_ref)
                             { ref: head_ref }
                           else
                             { commit: compare.commit }
                           end

      environment_params[:find_latest] = true
      @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(
        source_project,
        current_user,
        environment_params
      ).execute.last
    end
  end

  def define_diff_notes_disabled
    @diff_notes_disabled = compare.present?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def merge_request
    @merge_request ||= MergeRequestsFinder.new(current_user, project_id: target_project.id).execute.opened
      .find_by(source_project: source_project, source_branch: head_ref, target_branch: start_ref)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def compare_params
    @compare_params ||= params.permit(:from, :to, :from_project_id, :straight, :to_project_id)
  end
end
