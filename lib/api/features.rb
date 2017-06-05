module API
  class Features < Grape::API
    before { authenticated_as_admin! }

    resource :features do
      desc 'Get a list of all features' do
        success Entities::Feature
      end
      get do
        features = Feature.all

        present features, with: Entities::Feature, current_user: current_user
      end

      desc 'Set the gate value for the given feature' do
        success Entities::Feature
      end
      params do
        requires :value, type: String, desc: '`true` or `false` to enable/disable, an integer for percentage of time'
      end
      post ':name' do
        feature = Feature.get(params[:name])

        if %w(0 false).include?(params[:value])
          feature.disable
        elsif params[:value] == 'true'
          feature.enable
        else
          feature.enable_percentage_of_time(params[:value].to_i)
        end

        present feature, with: Entities::Feature, current_user: current_user
      end
    end
  end
end
