# frozen_string_literal: true

module Import
  class ImportRecordPreparer
    DIFF_NOTE_TO_DISCUSSION_NOTE_EXCLUDED_ATTRS = %w[
      original_position change_position position line_code type commit_id
    ].freeze

    DIFF_NOTE_RECOVERABLE_ERRORS = %i[missing_diff_file missing_diff_line].freeze

    SUPPORTED_TYPES = [DiffNote].freeze

    def self.recover_invalid_record(record)
      return record unless SUPPORTED_TYPES.include?(record.class)

      new(record).recover_invalid_record
    end

    def initialize(record)
      @record = record
    end

    # If we notice this is being used for many models in the future we should consider refactoring,
    # so each model has its own preparer. We can use metaprogramming to infer the preparer class.
    def recover_invalid_record
      create_discussion_note_on_missing_diff || record

      # As we support more types, we can start to follow this pattern:
      # case record
      # when DiffNote
      #   create_discussion_note_on_missing_diff
      # when Issue
      #  prepare_issue
      # end || record
    end

    private

    attr_reader :record

    def create_discussion_note_on_missing_diff
      return unless record.errors.details[:base].any? { |error| DIFF_NOTE_RECOVERABLE_ERRORS.include?(error[:error]) }

      new_note = "*Comment on"

      new_note += " #{record.position.old_path}:#{record.position.old_line} -->" if record.position.old_line
      new_note += " #{record.position.new_path}:#{record.position.new_line}" if record.position.new_line
      new_note += "*\n\n#{record.note}"

      DiscussionNote.new(record.attributes.except(*DIFF_NOTE_TO_DISCUSSION_NOTE_EXCLUDED_ATTRS)).tap do |note|
        note.note = new_note
        note.importing = record.importing
      end
    end
  end
end
