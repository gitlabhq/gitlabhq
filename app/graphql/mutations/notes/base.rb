# frozen_string_literal: true

module Mutations
  module Notes
    class Base < BaseMutation
      field :note,
            Types::Notes::NoteType,
            null: true,
            description: 'The note after mutation'

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id)
      end

      def check_object_is_noteable!(object)
        unless object.is_a?(Noteable)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                'Cannot add notes to this resource'
        end
      end

      def check_object_is_note!(object)
        unless object.is_a?(Note)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                'Resource is not a note'
        end
      end
    end
  end
end
