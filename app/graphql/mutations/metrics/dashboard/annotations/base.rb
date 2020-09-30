# frozen_string_literal: true

module Mutations
  module Metrics
    module Dashboard
      module Annotations
        class Base < BaseMutation
          private

          # This method is defined here in order to be used by `authorized_find!` in the subclasses.
          def find_object(id:)
            GitlabSchema.object_from_id(id, expected_type: ::Metrics::Dashboard::Annotation)
          end
        end
      end
    end
  end
end
