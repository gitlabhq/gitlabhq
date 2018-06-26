module API
  class Unleash < Grape::API
    include PaginationParams

    before do
      unauthorized! unless access_token
    end

    get ':unleash/features' do
      present @project, with: Entities::UnleashFeatures
    end

    post 'unleash/client/register' do
      status :ok
    end

    post 'unleash/client/metrics' do
      status :ok
    end

    private

    helpers do
      def project
        @project ||= find_project(unleash_appname)
      end

      def access_token
        @access_token ||= ProjectFeatureFlagsAccessToken.find_by(token: unleash_instanceid, project: project)
      end

      def unleash_appname
        params[:appname] || env[:HTTP_UNLEASH_APPNAME]
      end

      def unleash_instanceid
        params[:instanceid] || env[:HTTP_UNLEASH_INSTANCEID]
      end
    end
  end
end
