# frozen_string_literal: true

require 'addressable/uri'

class Projects::CompareController < Projects::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersCommits
  include CompareHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  # Defining ivars
  before_action :define_diffs, only: [:show, :diff_for_path]
  before_action :define_environment, only: [:show]
  before_action :define_diff_notes_disabled, only: [:show, :diff_for_path]
  before_action :define_commits, only: [:show, :diff_for_path, :signatures]
  before_action :merge_request, only: [:index, :show]
  # Validation
  before_action :validate_refs!

  before_action do
    push_frontend_feature_flag(:compare_repo_dropdown, source_project, default_enabled: :yaml)
  end

  feature_category :source_code_management

  # Diffs may be pretty chunky, the less is better in this endpoint.
  # Pagination design guides: https://design.gitlab.com/components/pagination/#behavior
  COMMIT_DIFFS_PER_PAGE = 20

  def index
  end

  def show
    apply_diff_view_cookie!

    render
  end

  def diff_for_path
    return render_404 unless compare

    render_diff_for_path(compare.diffs(diff_options))
  end

  def create
    from_to_vars = {
      from: params[:from].presence,
      to: params[:to].presence,
      from_project_id: params[:from_project_id].presence
    }

    if from_to_vars[:from].blank? || from_to_vars[:to].blank?
      flash[:alert] = "You must select a Source and a Target revision"

      redirect_to project_compare_index_path(source_project, from_to_vars)
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

  private

  def validate_refs!
    invalid = [head_ref, start_ref].filter { |ref| !valid_ref?(ref) }

    return if invalid.empty?

    flash[:alert] = "Invalid branch name(s): #{invalid.join(', ')}"
    redirect_to project_compare_index_path(source_project)
  end

  # target == start_ref == from
  def target_project
    strong_memoize(:target_project) do
      next source_project unless params.key?(:from_project_id)
      next source_project unless Feature.enabled?(:compare_repo_dropdown, source_project, default_enabled: :yaml)
      next source_project if params[:from_project_id].to_i == source_project.id

      target_project = target_projects(source_project).find_by_id(params[:from_project_id])

      # Just ignore the field if it points at a non-existent or hidden project
      next source_project unless target_project && can?(current_user, :download_code, target_project)

      target_project
    end
  end

  # source == head_ref == to
  def source_project
    project
  end

  def compare
    return @compare if defined?(@compare)

    @compare = CompareService.new(source_project, head_ref).execute(target_project, start_ref)
  end

  def start_ref
    @start_ref ||= Addressable::URI.unescape(params[:from])
  end

  def head_ref
    return @ref if defined?(@ref)

    @ref = @head_ref = Addressable::URI.unescape(params[:to])
  end

  def define_commits
    @commits = compare.present? ? set_commits_for_rendering(@compare.commits) : []
  end

  def define_diffs
    @diffs = compare.present? ? compare.diffs(diff_options) : []
  end

  def define_environment
    if compare
      environment_params = source_project.repository.branch_exists?(head_ref) ? { ref: head_ref } : { commit: compare.commit }
      environment_params[:find_latest] = true
      @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(source_project, current_user, environment_params).execute.last
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
end
