# frozen_string_literal: true

module API
  module Entities
    class Note < Grape::Entity
      # Only Issue and MergeRequest have iid
      NOTEABLE_TYPES_WITH_IID = %w[Issue MergeRequest].freeze

      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :type, documentation: { type: 'String', example: 'DiscussionNote' }

      expose :body, documentation: { type: 'String', example: 'Note body.' } do |note|
        NotePresenter.new(note, current_user: options[:current_user]).note
      end

      expose :author, using: ::API::Entities::UserBasic
      expose :created_at, documentation: { type: 'DateTime', example: '2022-01-31T15:10:44.988Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2022-01-31T15:10:44.988Z' }
      expose :system?, as: :system, documentation: { type: 'Boolean', example: false }
      expose :noteable_id, documentation: { type: 'Integer', example: 1 }
      expose :noteable_type, documentation: { type: 'String', example: 'Issue' }
      expose :project_id, documentation: { type: 'Integer', example: 1 }
      expose :commit_id, documentation: { type: 'String', example: '7b09ce7e6f80347baf0316c8c94cdba9a0a7e91d' },
        if: ->(note, _options) { note.noteable_type == "MergeRequest" && note.is_a?(DiffNote) }

      expose :position, documentation: { type: 'Hash' }, if: ->(note, _options) { note.is_a?(DiffNote) } do |note|
        note.position.to_h.except(:ignore_whitespace_change)
      end

      expose :resolvable?, as: :resolvable, documentation: { type: 'Boolean', example: false }
      expose :resolved?, as: :resolved, documentation: { type: 'Boolean', example: false },
        if: ->(note, _options) { note.resolvable? }
      expose :resolved_by, using: ::API::Entities::UserBasic, if: ->(note, _options) { note.resolvable? }
      expose :resolved_at, documentation: { type: 'DateTime', example: '2022-01-31T15:10:44.988Z' },
        if: ->(note, _options) { note.resolvable? }

      expose :suggestions,
        if: ->(note, _options) { note.noteable_type == "MergeRequest" && note.is_a?(DiffNote) },
        using: ::API::Entities::Suggestion

      expose :confidential?, as: :confidential, documentation: { type: 'Boolean', example: false }
      expose :confidential?, as: :internal, documentation: { type: 'Boolean', example: false }
      expose :imported?, as: :imported, documentation: { type: 'Boolean', example: false }
      expose :imported_from, documentation: { type: 'String', example: 'github' }

      # Avoid N+1 queries as much as possible
      expose(:noteable_iid, documentation: { type: 'Integer', example: 1 }) do |note|
        note.noteable.iid if NOTEABLE_TYPES_WITH_IID.include?(note.noteable_type)
      end

      expose(:commands_changes, documentation: { type: 'Hash' }) { |note| note.commands_changes || {} }
    end

    # To be returned if the note was command-only
    class NoteCommands < Grape::Entity
      expose(:commands_changes, documentation: { type: 'Hash' }) { |note| note.commands_changes || {} }
      expose(:summary, documentation: { type: 'String', is_array: true }) { |note| note.quick_actions_status.messages }
    end
  end
end
