# frozen_string_literal: true

module Commits
  class TagService < BaseService
    def execute(commit)
      unless params[:tag_name]
        return error('Missing parameter tag_name')
      end

      tag_name = params[:tag_name]
      message = params[:tag_message]

      result = Tags::CreateService
        .new(commit.project, current_user)
        .execute(tag_name, commit.sha, message)

      if result[:status] == :success
        tag = result[:tag]
        SystemNoteService.tag_commit(commit, commit.project, current_user, tag.name)
      end

      result
    end
  end
end
