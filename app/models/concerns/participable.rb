# == Participable concern
#
# Contains functionality related to objects that can have participants, such as
# an author, an assignee and people mentioned in its description or comments.
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
#
#       participant -> (current_user, ext) do
#         ext.analyze('...')
#       end
#     end
#
#     issue = Issue.last
#     users = issue.participants
module Participable
  extend ActiveSupport::Concern

  module ClassMethods
    # Adds a list of participant attributes. Attributes can either be symbols or
    # Procs.
    #
    # When using a Proc instead of a Symbol the Proc will be given two
    # arguments:
    #
    # 1. The current user (as an instance of User)
    # 2. An instance of `Gitlab::ReferenceExtractor`
    #
    # It is expected that a Proc populates the given reference extractor
    # instance with data. The return value of the Proc is ignored.
    #
    # attr - The name of the attribute or a Proc
    def participant(attr)
      participant_attrs << attr
    end
  end

  included do
    # Accessor for participant attributes.
    cattr_accessor :participant_attrs, instance_accessor: false do
      []
    end
  end

  # Returns the users participating in a discussion.
  #
  # This method processes attributes of objects in breadth-first order.
  #
  # Returns an Array of User instances.
  def participants(current_user = nil)
    all_participants[current_user]
  end

  private

  def all_participants
    @all_participants ||= Hash.new do |hash, user|
      hash[user] = raw_participants(user)
    end
  end

  def raw_participants(current_user = nil)
    current_user ||= author
    ext = Gitlab::ReferenceExtractor.new(project, current_user)
    participants = Set.new
    process = [self]

    until process.empty?
      source = process.pop

      case source
      when User
        participants << source
      when Participable
        source.class.participant_attrs.each do |attr|
          if attr.respond_to?(:call)
            source.instance_exec(current_user, ext, &attr)
          else
            process << source.__send__(attr) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      when Enumerable, ActiveRecord::Relation
        # This uses reverse_each so we can use "pop" to get the next value to
        # process (in order). Using unshift instead of pop would require
        # moving all Array values one index to the left (which can be
        # expensive).
        source.reverse_each { |obj| process << obj }
      end
    end

    participants.merge(ext.users)

    case self
    when PersonalSnippet
      Ability.users_that_can_read_personal_snippet(participants.to_a, self)
    else
      Ability.users_that_can_read_project(participants.to_a, project)
    end
  end
end
