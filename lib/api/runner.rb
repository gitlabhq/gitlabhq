module API
  class Runner < Grape::API
    helpers ::API::Helpers::Runner

    resource :runners do
      desc 'Registers a new Runner' do
        success Entities::RunnerRegistrationDetails
        http_codes [[201, 'Runner was created'], [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: 'Registration token'
        optional :description, type: String, desc: %q(Runner's description)
        optional :info, type: Hash, desc: %q(Runner's metadata)
        optional :locked, type: Boolean, desc: 'Should Runner be locked for current project'
        optional :run_untagged, type: Boolean, desc: 'Should Runner handle untagged jobs'
        optional :tag_list, type: Array[String], desc: %q(List of Runner's tags)
      end
      post '/' do
        attributes = attributes_for_keys [:description, :locked, :run_untagged, :tag_list]

        runner =
          if runner_registration_token_valid?
            # Create shared runner. Requires admin access
            Ci::Runner.create(attributes.merge(is_shared: true))
          elsif project = Project.find_by(runners_token: params[:token])
            # Create a specific runner for project.
            project.runners.create(attributes)
          end

        return forbidden! unless runner

        if runner.id
          runner.update(get_runner_version_from_params)
          present runner, with: Entities::RunnerRegistrationDetails
        else
          not_found!
        end
      end

      desc 'Deletes a registered Runner' do
        http_codes [[204, 'Runner was deleted'], [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: %q(Runner's authentication token)
      end
      delete '/' do
        authenticate_runner!
        Ci::Runner.find_by_token(params[:token]).destroy
      end
    end
  end
end
