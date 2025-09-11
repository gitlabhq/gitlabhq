# frozen_string_literal: true

require 'gitlab'
require 'logger'

class UpdateMergeRequestsLabel
  PROJECT_ID = '41365521' # Using gitlab-com/gl-infra/release-environments project id

  def initialize
    @client = Gitlab.client(endpoint: api_endpoint, private_token: api_token)
    @logger = Logger.new($stdout)
  end

  def execute
    return if deployment_mrs.empty?

    @logger.info("Found #{deployment_mrs.count} merge requests for deployment #{deployment_id}.")

    deployment_mrs.each do |mr|
      @logger.info("Adding label 'workflow::release-environment' to merge request #{mr.web_url} ...")
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
        @logger.error("Could not add label 'workflow::release-environment' to merge request #{mr.web_url}." \
          "\n[ERROR]: #{e.message}")
      end
    end
  end

  private

  def deployment_mrs
    @client.get("/projects/#{PROJECT_ID}/deployments/#{deployment_id}/merge_requests")
  rescue StandardError => e
    @logger.error("Could not retrieve merge requests for deployment #{deployment_id}.\n[ERROR]: #{e.message}")
    [] # Return empty array on error
  end

  def api_endpoint
    ENV.fetch('CI_API_V4_URL')
  end

  def api_token
    ENV.fetch('COM_RELEASE_TOOLS_BOT')
  end

  def deployment_id
    ENV.fetch('DEPLOYMENT_ID')
  end
end

UpdateMergeRequestsLabel.new.execute if $PROGRAM_NAME == __FILE__
