# == Participable concern
#
# Contains functionality related to objects that can have participants, such as
# an author, an assignee and people mentioned in its description or comments.
#
# Used by Issue, Note, MergeRequest, Snippet and Commit.
#
# Usage:
#
#     class Issue < ActiveRecord::Base
#       include Participable
#     end
#
#     issue = Issue.last
#     users = issue.participants
#     # `users` will contain the issue's author, its assignee,
#     # all users returned by its #mentioned_users method,
#     # as well as all participants to all of the issue's notes,
#     # since Note implements Participable as well.
#
module Participable
  def participants
    @participants ||=
      begin
        user_ids = Participant.
          where(target_id: id.to_s, target_type: self.class.name).
          pluck(:user_id)

        User.where(id: user_ids)
      end
  end
end
