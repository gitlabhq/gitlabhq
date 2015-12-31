module API
  class LicenseInfo < Grape::API
    before { authenticated_as_admin! }

    resource :license do

      # Get information on the currently active license
      #
      # Example request:
      #   GET /license
      get do
        @license = License.current

        present @license, with: Entities::License
      end
    end
  end
end
