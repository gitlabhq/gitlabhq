# frozen_string_literal: true

module Subscriptions
  module Notes
    class Deleted < Base
      payload_type ::Types::Notes::DeletedNoteType

      DeletedNote = Struct.new(:model_id, :model_name, :discussion_model_id, :last_discussion_note) do
        def to_global_id
          ::Gitlab::GlobalId.as_global_id(model_id, model_name: model_name)
        end

        def discussion_id
          ::Gitlab::GlobalId.as_global_id(discussion_model_id, model_name: Discussion.name)
        end
      end

      def update(*args)
        DeletedNote.new(object[:id], object[:model_name], object[:discussion_id], object[:last_discussion_note])
      end
    end
  end
end
