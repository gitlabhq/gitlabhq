# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Base < BaseMutation
        JobID = ::Types::GlobalIDType[::Ci::Build]

        argument :id, JobID,
          required: true,
          description: 'ID of the job to mutate.'
      end
    end
  end
end
