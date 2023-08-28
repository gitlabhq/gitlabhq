# frozen_string_literal: true

module Noteable
  class NotesChannel < ApplicationCable::Channel
    def subscribed
      project = Project.find(params[:project_id]) if params[:project_id].present?

      noteable = NotesFinder.new(current_user, {
        project: project,
        group_id: params[:group_id],
        target_type: params[:noteable_type],
        target_id: params[:noteable_id]
      }).target

      return reject if noteable.nil?

      stream_for noteable
    rescue ActiveRecord::RecordNotFound
      reject
    end
  end
end
