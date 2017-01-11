module API
  class License < Grape::API
    before { authenticated_as_admin! }

    resource :license do
      desc 'Get information on the currently active license' do
        success Entities::License
      end
      get do
        license = ::License.current

        present license, with: Entities::License
      end

      desc 'Add a new license' do
        success Entities::License
      end
      params do
        requires :license, type: String, desc: 'The license text'
      end
      post do
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
