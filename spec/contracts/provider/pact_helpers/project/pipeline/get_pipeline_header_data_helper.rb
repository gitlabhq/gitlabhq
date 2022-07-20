# frozen_string_literal: true

require_relative '../../../spec_helper'
require_relative '../../../states/project/pipeline/pipeline_state'

module Provider
  module GetPipelinesHeaderDataHelper
    Pact.service_provider "GET pipeline header data" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#show' do
        pact_uri '../contracts/project/pipeline/show/pipelines#show-get_project_pipeline_header_data.json'
      end
    end
  end
end
