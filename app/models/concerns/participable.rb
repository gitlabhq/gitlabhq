# frozen_string_literal: true

# == Participable concern
#
# Contains functionality related to objects that can have participants, such as
# an author, an assignee and people mentioned in its description or comments.
#
# Usage:
#
#     class Issue < ApplicationRecord
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
  class_methods do
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
  def participants(user = nil)
    filtered_participants_hash[user]
  end

  # Returns only participants visible for the user
  #
  # Returns an Array of User instances.
  def visible_participants(user)
    filter_by_ability(raw_participants(user, verify_access: true))
  end

  # Checks if the user is a participant in a discussion.
  #
  # This method processes attributes of objects in breadth-first order.
  #
  # Returns a Boolean.
  def participant?(user)
    can_read_participable?(user) &&
      all_participants_hash[user].include?(user)
  end

  private

  def all_participants_hash
    @all_participants_hash ||= Hash.new do |hash, user|
      hash[user] = raw_participants(user)
    end
  end

  def filtered_participants_hash
    @filtered_participants_hash ||= Hash.new do |hash, user|
      hash[user] = filter_by_ability(all_participants_hash[user])
    end
  end

  def raw_participants(current_user = nil, verify_access: false)
    extractor = Gitlab::ReferenceExtractor.new(project, current_user)

    # Used to extract references from confidential notes.
    # Referenced users that cannot read confidential notes are
    # later removed from participants array.
    internal_notes_extractor = Gitlab::ReferenceExtractor.new(project, current_user)

    participants = Set.new
    process = [self]

    until process.empty?
      source = process.pop

      case source
      when User
        participants << source
      when Participable
        next if skippable_system_notes?(source, participants)
        next unless !verify_access || source_visible_to_user?(source, current_user)

        source.class.participant_attrs.each do |attr|
          if attr.respond_to?(:call)
            ext = use_internal_notes_extractor_for?(source) ? internal_notes_extractor : extractor

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

    participants.merge(users_that_can_read_internal_notes(internal_notes_extractor))
    participants.merge(extractor.users)
  end

  def skippable_system_notes?(source, participants)
    source.is_a?(Note) &&
      source.system? &&
      source.author.in?(participants) &&
      !source.note.match?(User.reference_pattern)
  end

  def use_internal_notes_extractor_for?(source)
    source.is_a?(Note) && source.confidential?
  end

  def users_that_can_read_internal_notes(extractor)
    return [] unless self.is_a?(Noteable) && self.try(:resource_parent)

    Ability.users_that_can_read_internal_notes(extractor.users, self.resource_parent)
  end

  def source_visible_to_user?(source, user)
    ability = read_ability_for(source)

    Ability.allowed?(user, ability[:name], ability[:subject])
  end

  def filter_by_ability(participants)
    case self
    when PersonalSnippet
      Ability.users_that_can_read_personal_snippet(participants.to_a, self)
    else
      return Ability.users_that_can_read_project(participants.to_a, project) if project

      # handling group level work items(issues) that would have a namespace,
      # We need to make sure that scenarios where some models that do not have a project set and also do not have
      # a namespace are also handled and exceptions are avoided.
      namespace_level_participable = respond_to?(:namespace) && namespace.present?
      return Ability.users_that_can_read_group(participants.to_a, namespace) if namespace_level_participable

      []
    end
  end

  def can_read_participable?(participant)
    case self
    when PersonalSnippet
      participant.can?(:read_snippet, self)
    else
      return participant.can?(:read_project, project) if project

      # handling group level work items(issues) that would have a namespace,
      # We need to make sure that scenarios where some models that do not have a project set and also do not have
      # a namespace are also handled and exceptions are avoided.
      namespace_level_participable = respond_to?(:namespace) && namespace.present?
      return participant.can?(:read_group, namespace) if namespace_level_participable

      false
    end
  end

  # Returns Hash containing ability name and subject needed to read a specific participable.
  # Should be overridden if a different ability is required.
  def read_ability_for(participable_source)
    name =  participable_source.try(:to_ability_name) || participable_source.model_name.element

    { name: "read_#{name}".to_sym, subject: participable_source }
  end
end

Participable.prepend_mod_with('Participable')
