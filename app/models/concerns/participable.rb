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
#       participant ->(current_user, ext) { all_references(current_user, ext: ext) }
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
    def participant(attr)
      participant_attrs << attr
    end

    def participant_attrs
      @participant_attrs ||= []
    end
  end

  # Returns the users participating in a discussion.
  #
  # Returns an Array of User instances.
  def participants(current_user = nil, ext: nil, filter_access: true, load_references: true)
    ext ||= Gitlab::ReferenceExtractor.new(project, current_user || author)

    participants = Set.new

    self.class.participant_attrs.each do |attr|
      value =
        if attr.respond_to?(:call)
          instance_exec(current_user, ext: ext, &attr)
        else
          send(attr)
        end

      next unless value

      result = participants_for(value, current_user: current_user, ext: ext)

      participants.merge(result) if result
    end

    participants.merge(ext.users) if load_references

    users = participants.to_a

    users = Ability.users_that_can_read_project(users, project) if filter_access

    users
  end

  private

  def participants_for(value, current_user: nil, ext: ext)
    case value
    when User
      [value]
    when Enumerable, ActiveRecord::Relation
      value.flat_map { |v| participants_for(v, current_user: current_user, ext: ext) }
    when Participable
      value.participants(current_user, ext: ext, filter_access: false, load_references: false)
    end
  end
end
