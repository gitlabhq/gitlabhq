# frozen_string_literal: true

module Commits
  class TagService < BaseService
    def execute(commit)
      # TODO authorize
      return unless params[:tag_name]

      tag_name = params[:tag_name]
      message = params[:tag_message]
      release_description = nil

      result = Tags::CreateService
        .new(commit.project, current_user)
        .execute(tag_name, commit.sha, message, release_description)

      if result[:status] == :success && (tag = result[:tag])
        SystemNoteService.tag_commit(commit, commit.project, current_user, tag.name)
        commit
      end
    end
  end
end
