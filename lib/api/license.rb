module API
  class License < Grape::API
    before { authenticated_as_admin! }

    resource :license do

      # Get information on the currently active license
      #
      # Example request:
      #   GET /license
      get do
        license = ::License.current

        present license, with: Entities::License
      end

      # Add a new license
      #
      # Parameters:
      #   license (required) - The license text
      #
      # Example request:
      #   POST /license
      post do
        required_attributes! [:license]

        license = ::License.new(data: params[:license])
        if license.save
          present license, with: Entities::License
        else
          render_api_error!(license.errors.full_messages.first, 400)
        end
      end
    end
  end
end
