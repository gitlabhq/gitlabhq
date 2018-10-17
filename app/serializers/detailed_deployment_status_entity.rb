# frozen_string_literal: true

class DetailedDeploymentStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :environment_text_for_pipeline
  expose :environment_text_for_job
  expose :environment_path
  expose :deployment_path
  expose :environment_name
  expose :metrics_url
  expose :metrics_monitoring_url
  expose :stop_url
  expose :external_url
  expose :external_url_formatted
  expose :deployed_at
  expose :deployed_at_formatted

end
