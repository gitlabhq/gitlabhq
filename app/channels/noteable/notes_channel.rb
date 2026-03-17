# frozen_string_literal: true

module Noteable
  class NotesChannel < ApplicationCable::Channel
    def subscribed
      project = Project.find(params[:project_id]) if params[:project_id].present?
      organization = connection.current_organization

      finder_params = {
        project: project,
        group_id: params[:group_id],
        target_type: params[:noteable_type],
        target_id: params[:noteable_id]
      }
      finder_params[:organization_id] = organization.id if organization

      noteable = NotesFinder.new(current_user, finder_params).target

      return reject if noteable.nil?

      stream_for noteable
    rescue ActiveRecord::RecordNotFound
      reject
    end
  end
end
