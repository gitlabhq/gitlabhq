# frozen_string_literal: true

module GoogleCloud
  class CreateCloudsqlInstanceWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :not_owned # rubocop:disable Gitlab/AvoidFeatureCategoryNotOwned
    idempotent!

    def perform(user_id, project_id, params = {})
      user = User.find(user_id)
      project = Project.find(project_id)
      params = params.with_indifferent_access

      response = ::CloudSeed::GoogleCloud::SetupCloudsqlInstanceService.new(project, user, params).execute

      if response[:status] == :error
        raise "Error SetupCloudsqlInstanceService: #{response.to_json}"
      end
    end
  end
end
