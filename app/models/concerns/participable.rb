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
#       participant :author
#       participant :assignee
#       participant :notes
#       participant ->(current_user) { mentioned_users(current_user) }
#     end
#
#     issue = Issue.last
#     users = issue.participants
#
#     # `users` will contain the issue's author, its assignee, and all users
#     # returned by its #mentioned_users method,
#
module Participable
  extend ActiveSupport::Concern

  module ClassMethods
    # Adds a list of participant attributes. Attributes can either be symbols or
    # Procs.
    #
    # attr - The name of the attribute or a Proc
    # index - The position of the returned object in the Array returned by
    #         `#participants`. By default the attribute is inserted at the end
    #         of the list.
    def participant(attr, index: -1)
      participant_attrs.insert(index, attr)
    end

    def participant_attrs
      @participant_attrs ||= []
    end
  end

  # Returns the users participating in a discussion.
  #
  # Returns an Array of User instances.
  def participants(current_user = self.author)
    participants = Set.new

    self.class.participant_attrs.each do |attr|
      value =
        if attr.respond_to?(:call)
          instance_exec(current_user, &attr)
        else
          send(attr)
        end

      next unless value

      result = participants_for(value, current_user)

      participants.merge(result) if result
    end

    Ability.users_that_can_read_project(participants.to_a, project)
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
