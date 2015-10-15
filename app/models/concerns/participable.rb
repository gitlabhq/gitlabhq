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
#     # `users` will contain the issue's author, its assignee,
#     # all users returned by its #mentioned_users method,
#     # as well as all participants to all of the issue's notes,
#     # since Note implements Participable as well.
#
module Participable
  extend ActiveSupport::Concern

  module ClassMethods
    def participant(*attrs)
      participant_attrs.concat(attrs)
    end

    def participant_attrs
      @participant_attrs ||= []
    end
  end

  # Be aware that this method makes a lot of sql queries.
  # Save result into variable if you are going to reuse it inside same request
  def participants(current_user = self.author, load_lazy_references: true)
    participants = self.class.participant_attrs.flat_map do |attr|
      value =
        if attr.respond_to?(:call)
          instance_exec(current_user, &attr)
        else
          send(attr)
        end

      participants_for(value, current_user)
    end.compact.uniq

    if load_lazy_references
      participants = Gitlab::Markdown::ReferenceFilter::LazyReference.load(participants).uniq

      participants.select! do |user|
        user.can?(:read_project, project)
      end
    end

    participants
  end

  private

  def participants_for(value, current_user = nil)
    case value
    when User, Gitlab::Markdown::ReferenceFilter::LazyReference
      [value]
    when Enumerable, ActiveRecord::Relation
      value.flat_map { |v| participants_for(v, current_user) }
    when Participable
      value.participants(current_user, load_lazy_references: false)
    end
  end
end
