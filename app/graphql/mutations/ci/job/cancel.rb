# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Cancel < Base
        graphql_name 'JobCancel'

        field :job,
          Types::Ci::JobType,
          null: true,
          description: 'Job after the mutation.'

        authorize :cancel_build

        def resolve(id:)
          job = authorized_find!(id: id)

          ::Ci::BuildCancelService.new(job, current_user).execute
          {
            job: job,
            errors: errors_on_object(job)
          }
        end
      end
    end
  end
end
