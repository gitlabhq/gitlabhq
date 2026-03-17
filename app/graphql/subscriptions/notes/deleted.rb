# frozen_string_literal: true

module Subscriptions
  module Notes
    class Deleted < Base
      include Gitlab::Utils::StrongMemoize

      payload_type ::Types::Notes::DeletedNoteType

      DeletedNote = Struct.new(:model_id, :model_name, :discussion_model_id, :last_discussion_note, :noteable) do
        def to_global_id
          ::Gitlab::GlobalId.as_global_id(model_id, model_name: model_name)
        end

        def discussion_id
          ::Gitlab::GlobalId.as_global_id(discussion_model_id, model_name: Discussion.name)
        end
      end

      private

      def note_object
        return if object.nil?

        DeletedNote.new(
          object[:id], object[:model_name], object[:discussion_id], object[:last_discussion_note], object[:noteable]
        )
      end
      strong_memoize_attr :note_object
    end
  end
end
