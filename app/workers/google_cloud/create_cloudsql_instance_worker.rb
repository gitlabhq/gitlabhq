# frozen_string_literal: true

module GoogleCloud
  class CreateCloudsqlInstanceWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :not_owned # rubocop:disable Gitlab/AvoidFeatureCategoryNotOwned
    idempotent!

    def perform(user_id, project_id, options = {})
      user = User.find(user_id)
      project = Project.find(project_id)

      google_oauth2_token = options[:google_oauth2_token]
      gcp_project_id = options[:gcp_project_id]
      instance_name = options[:instance_name]
      database_version = options[:database_version]
      environment_name = options[:environment_name]
      is_protected = options[:is_protected]

      params = {
        google_oauth2_token: google_oauth2_token,
        gcp_project_id: gcp_project_id,
        instance_name: instance_name,
        database_version: database_version,
        environment_name: environment_name,
        is_protected: is_protected
      }

      response = GoogleCloud::SetupCloudsqlInstanceService.new(project, user, params).execute

      if response[:status] == :error
        raise response[:message]
      end
    end
  end
end
