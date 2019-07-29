# frozen_string_literal: true

class ZoomNotesService
  def initialize(issue, project, current_user, old_description: nil)
    @issue = issue
    @project = project
    @current_user = current_user
    @old_description = old_description
  end

  def execute
    return if @issue.description == @old_description

    if zoom_link_added?
      zoom_link_added_notification
    elsif zoom_link_removed?
      zoom_link_removed_notification
    end
  end

  private

  def zoom_link_added?
    has_zoom_link?(@issue.description) && !has_zoom_link?(@old_description)
  end

  def zoom_link_removed?
    !has_zoom_link?(@issue.description) && has_zoom_link?(@old_description)
  end

  def has_zoom_link?(text)
    Gitlab::ZoomLinkExtractor.new(text).match?
  end

  def zoom_link_added_notification
    SystemNoteService.zoom_link_added(@issue, @project, @current_user)
  end

  def zoom_link_removed_notification
    SystemNoteService.zoom_link_removed(@issue, @project, @current_user)
  end
end
