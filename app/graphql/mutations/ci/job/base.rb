# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Base < BaseMutation
        JobID = ::Types::GlobalIDType[::Ci::Build]

        argument :id, JobID,
                 required: true,
                 description: 'The ID of the job to mutate.'

        def find_object(id: )
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = JobID.coerce_isolated_input(id)
          GlobalID::Locator.locate(id)
        end
      end
    end
  end
end
