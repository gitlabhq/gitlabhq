# frozen_string_literal: true

module Notes
  module Discussion
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      scope :with_discussion_ids, ->(discussion_ids) { where(discussion_id: discussion_ids) }
    end

    class_methods do
      def discussions(context_noteable = nil)
        ::Discussion.build_collection(all.includes(parent_object_field).fresh, context_noteable)
      end

      def find_discussion(discussion_id)
        notes = where(discussion_id: discussion_id).fresh.to_a

        return if notes.empty?

        ::Discussion.build(notes)
      end
    end

    def ensure_discussion_id
      return if attribute_present?(:discussion_id)

      self.discussion_id = derive_discussion_id
    end

    def derive_discussion_id
      discussion_class.discussion_id(self)
    end

    # See `Discussion.override_discussion_id` for details.
    def discussion_id(noteable = nil)
      discussion_class(noteable).override_discussion_id(self) || super() || ensure_discussion_id
    end

    # Returns a discussion containing just this note.
    # This method exists as an alternative to `#discussion` to use when the methods
    # we intend to call on the Discussion object don't require it to have all of its notes,
    # and just depend on the first note or the type of discussion. This saves us a DB query.
    def to_discussion(noteable = nil)
      ::Discussion.build([self], noteable)
    end

    # Returns the entire discussion this note is part of.
    # Consider using `#to_discussion` if we do not need to render the discussion
    # and all its notes and if we don't care about the discussion's resolvability status.
    def discussion
      full_discussion = noteable.notes.find_discussion(discussion_id) if noteable && part_of_discussion?

      full_discussion || to_discussion
    end
    strong_memoize_attr :discussion

    def start_of_discussion?
      discussion.first_note == self
    end

    def part_of_discussion?
      !to_discussion.individual_note?
    end

    def discussion_class(other_noteable = nil)
      return IndividualNoteDiscussion unless other_noteable

      sync_object = other_noteable.try(:sync_object)

      # When commit notes are rendered on an MR's Discussion page, they are
      # displayed in one discussion instead of individually.
      # See also `#discussion_id` and `Discussion.override_discussion_id`.
      if !sync_object.present? && !current_noteable?(other_noteable)
        OutOfContextDiscussion
      else
        IndividualNoteDiscussion
      end
    end

    def in_reply_to?(other)
      case other
      when Note, AntiAbuse::Reports::Note
        if part_of_discussion?
          in_reply_to?(other.noteable) && in_reply_to?(other.to_discussion)
        else
          in_reply_to?(other.noteable)
        end
      when ::Discussion, AntiAbuse::Reports::Discussion
        discussion_id == other.id
      when Noteable
        noteable == other
      else
        false
      end
    end

    private

    def current_noteable?(other_noteable)
      other_noteable.id == noteable&.id && other_noteable.base_class_name == noteable&.base_class_name
    end
  end
end
