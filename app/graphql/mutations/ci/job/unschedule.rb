# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class Unschedule < Base
        graphql_name 'JobUnschedule'

        field :job,
          Types::Ci::JobType,
          null: true,
          description: 'Job after the mutation.'

        authorize :update_build

        def resolve(id:)
          job = authorized_find!(id: id)

          ::Ci::BuildUnscheduleService.new(job, current_user).execute
          {
            job: job,
            errors: errors_on_object(job)
          }
        end
      end
    end
  end
end
