# frozen_string_literal: true

class Projects::DiscussionsController < Projects::ApplicationController
  include NotesHelper
  include RendersNotes

  before_action :check_noteable_supports_resolvable_notes!
  before_action :noteable
  before_action :discussion, only: [:resolve, :unresolve]
  before_action :authorize_resolve_discussion!, only: [:resolve, :unresolve]

  feature_category :team_planning
  urgency :low

  def resolve
    Discussions::ResolveService.new(project, current_user, one_or_more_discussions: discussion).execute

    render_discussion
  end

  def unresolve
    Discussions::UnresolveService.new(discussion, current_user).execute

    render_discussion
  end

  def show
    render json: {
      truncated_diff_lines: discussion.try(:truncated_diff_lines)
    }
  end

  private

  def render_discussion
    prepare_notes_for_rendering(discussion.notes)
    render_json_with_discussions_serializer
  end

  def render_json_with_discussions_serializer
    render json:
      DiscussionSerializer.new(
        project: project,
        noteable: discussion.noteable,
        current_user: current_user,
        note_entity: ProjectNoteEntity
      )
      .represent(discussion, context: self, render_truncated_diff_lines: true)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def noteable
    @noteable ||= noteable_finder_class.new(current_user, project_id: @project.id).find_by!(iid: params[:noteable_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def noteable_finder_class
    case params[:noteable_type]
    when 'issues'
      IssuesFinder
    when 'merge_requests'
      MergeRequestsFinder
    end
  end

  def check_noteable_supports_resolvable_notes!
    render_404 unless noteable_finder_class && noteable&.supports_resolvable_notes?
  end

  def discussion
    @discussion ||= @noteable.find_discussion(params[:id]) || render_404
  end

  def authorize_resolve_discussion!
    access_denied! unless discussion.can_resolve?(current_user)
  end
end
