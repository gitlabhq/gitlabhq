# frozen_string_literal: true

require 'gitlab'
require 'logger'

class UpdateMergeRequestsLabel
  def initialize
    @client = Gitlab.client(endpoint: api_endpoint, private_token: api_token)
  end

  def execute
    return if deployment_mrs.empty?

    deployment_mrs.each do |mr|
      labels = mr.labels

      # Remove existing workflow labels from the list
      labels.reject! { |l| l.start_with?("workflow::") }
      begin
        @client.update_merge_request(
          mr.project_id,
          mr.iid,
          labels: ['workflow::release-environment', *labels].join(',')
        )
      rescue StandardError => e
        logger.error("Could not update backport MR iid #{mr.iid} with " \
          "label 'workflow::release-environment'.\n[ERROR]: #{e.message}")
      end
    end
  end

  private

  def deployment_mrs
    @client.get("/projects/#{project_id}/deployments/#{deployment_id}/merge_requests")
  rescue StandardError => e
    logger.error("Could not retrieve merge requests for deployment #{deployment_id}.\n[ERROR]: #{e.message}")
    [] # Return empty array on error
  end

  def api_endpoint
    ENV.fetch('CI_API_V4_URL')
  end

  def project_id
    ENV.fetch('CI_PROJECT_ID')
  end

  def api_token
    ENV.fetch('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE')
  end

  def deployment_id
    ENV.fetch('DEPLOYMENT_ID')
  end
end

UpdateMergeRequestsLabel.new.execute if $PROGRAM_NAME == __FILE__
