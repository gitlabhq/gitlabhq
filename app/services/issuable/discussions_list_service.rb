# frozen_string_literal: true

# This service return notes grouped by discussion ID and paginated per discussion.
# System notes also have a discussion ID assigned including Synthetic system notes.
module Issuable
  class DiscussionsListService
    include Gitlab::Utils::StrongMemoize

    attr_reader :current_user, :issuable, :params

    def initialize(current_user, issuable, params = {})
      @current_user = current_user
      @issuable = issuable
      @params = params.dup
    end

    def execute
      return Note.none unless can_read_issuable_notes?

      notes = NotesFinder.new(current_user, params.merge({ target: issuable, project: issuable.project }))
                .execute.with_web_entity_associations.inc_relations_for_view(issuable).fresh

      if paginator
        paginated_discussions_by_type = paginator.records.group_by(&:table_name)

        notes = if paginated_discussions_by_type['notes'].present?
                  notes.id_in(paginated_discussions_by_type['notes'].flat_map(&:ids))
                else
                  notes.none
                end
      end

      if params[:notes_filter] != UserPreference::NOTES_FILTERS[:only_comments]
        notes = ResourceEvents::MergeIntoNotesService.new(
          issuable, current_user, paginated_notes: paginated_discussions_by_type
        ).execute(notes)
      end

      # Here we assume all notes belong to the same project as the work item
      project = notes.first&.project
      notes = ::Preloaders::Projects::NotesPreloader.new(project, current_user).call(notes)

      # we need to check the permission on every note, because some system notes for instance can have references to
      # resources that some user do not have read access, so those notes are filtered out from the list of notes.
      # see Note#all_referenced_mentionables_allowed?
      notes = notes.select { |n| n.readable_by?(current_user) }

      Discussion.build_collection(notes, issuable)
    end

    def paginator
      return if params[:per_page].blank?

      strong_memoize(:paginator) do
        issuable
          .discussion_root_note_ids(notes_filter: params[:notes_filter])
          .keyset_paginate(cursor: params[:cursor], per_page: params[:per_page].to_i)
      end
    end

    def can_read_issuable_notes?
      return Ability.allowed?(current_user, :read_security_resource, issuable) if issuable.is_a?(Vulnerability)

      Ability.allowed?(current_user, :"read_#{issuable.to_ability_name}", issuable) &&
        Ability.allowed?(current_user, :read_note, issuable)
    end
  end
end
