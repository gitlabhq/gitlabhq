module API
  class Features < Grape::API
    before { authenticated_as_admin! }

    helpers do
      def gate_value(params)
        case params[:value]
        when 'true'
          true
        when '0', 'false'
          false
        else
          params[:value].to_i
        end
      end

      def gate_target(params)
        if params[:feature_group]
          Feature.group(params[:feature_group])
        elsif params[:user]
          User.find_by_username(params[:user])
        else
          gate_value(params)
        end
      end
    end

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
        optional :feature_group, type: String, desc: 'A Feature group name'
        optional :user, type: String, desc: 'A GitLab username'
        mutually_exclusive :feature_group, :user
      end
      post ':name' do
        feature = Feature.get(params[:name])
        target = gate_target(params)
        value = gate_value(params)

        case value
        when true
          feature.enable(target)
        when false
          feature.disable(target)
        else
          feature.enable_percentage_of_time(value)
        end

        present feature, with: Entities::Feature, current_user: current_user
      end
    end
  end
end
