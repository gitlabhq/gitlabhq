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
#
#       # ...
#
#       participant :author, :assignee, :notes, ->(current_user) { mentioned_users(current_user) }
#     end
#
#     issue = Issue.last
#     users = issue.participants
#
#     # `users` will contain the issue's author, its assignee, and # all users
#     # returned by its #mentioned_users method,
#
module Participable
  extend ActiveSupport::Concern

  module ClassMethods
    # Adds a list of participant attributes. Attributes can either be symbols or
    # Procs.
    def participant(*attrs)
      participant_attrs.concat(attrs)
    end

    def participant_attrs
      @participant_attrs ||= []
    end
  end

  # Returns the users participating in a discussion.
  #
  # For every regular attribute this method will check if the returned user can
  # read the current project. When a Proc is used this method assumes the Proc's
  # return value _only_ includes users that have the appropriate permissions.
  # This requirement is put in place to reduce the number of queries needed to
  # check if every user has access to the project.
  #
  # Returns an Array of User instances.
  def participants(current_user = self.author)
    participants = Set.new

    self.class.participant_attrs.each do |attr|
      check = false
      value =
        if attr.respond_to?(:call)
          instance_exec(current_user, &attr)
        else
          check = true
          send(attr)
        end

      next unless value

      result = participants_for(value, current_user)

      if result
        result.select! { |user| user.can?(:read_project, project) } if check

        participants.merge(result)
      end
    end

    participants.to_a
  end

  private

  def participants_for(value, current_user = nil)
    case value
    when User
      [value]
    when Enumerable, ActiveRecord::Relation
      value.flat_map { |v| participants_for(v, current_user) }
    when Participable
      value.participants(current_user)
    end
  end
end
