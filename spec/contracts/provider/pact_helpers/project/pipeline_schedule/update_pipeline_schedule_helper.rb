# frozen_string_literal: true

require_relative '../../../spec_helper'
require_relative '../../../states/project/pipeline_schedule/edit_state'

module Provider
  module CreateNewPipelineHelper
    Pact.service_provider "PUT Edit a pipeline schedule" do
      app { Environments::Test.app }

      honours_pact_with 'PipelineSchedule#edit' do
        pact_uri '../contracts/project/pipeline_schedule/edit/pipelineschedules#edit-put_edit_a_pipeline_schedule.json'
      end

      app_version Provider::PublishContractHelper::PROVIDER_VERSION
      app_version_branch Provider::PublishContractHelper::PROVIDER_BRANCH
      publish_verification_results Provider::PublishContractHelper::PUBLISH_FLAG
    end
  end
end
