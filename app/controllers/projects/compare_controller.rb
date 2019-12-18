# frozen_string_literal: true

require 'addressable/uri'

class Projects::CompareController < Projects::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersCommits

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
    if params[:from].blank? || params[:to].blank?
      flash[:alert] = "You must select a Source and a Target revision"
      from_to_vars = {
        from: params[:from].presence,
        to: params[:to].presence
      }
      redirect_to project_compare_index_path(@project, from_to_vars)
    else
      redirect_to project_compare_path(@project,
                                               params[:from], params[:to])
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
    valid = [head_ref, start_ref].map { |ref| valid_ref?(ref) }

    return if valid.all?

    flash[:alert] = "Invalid branch name"
    redirect_to project_compare_index_path(@project)
  end

  def compare
    return @compare if defined?(@compare)

    @compare = CompareService.new(@project, head_ref).execute(@project, start_ref)
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
      environment_params = @repository.branch_exists?(head_ref) ? { ref: head_ref } : { commit: compare.commit }
      environment_params[:find_latest] = true
      @environment = EnvironmentsFinder.new(@project, current_user, environment_params).execute.last
    end
  end

  def define_diff_notes_disabled
    @diff_notes_disabled = compare.present?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def merge_request
    @merge_request ||= MergeRequestsFinder.new(current_user, project_id: @project.id).execute.opened
      .find_by(source_project: @project, source_branch: head_ref, target_branch: start_ref)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
