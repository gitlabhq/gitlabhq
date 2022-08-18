# frozen_string_literal: true

require_relative '../../../../spec_helper'
require_relative '../../../../states/project/pipeline/show_state'

module Provider
  module DeletePipelineHelper
    Pact.service_provider "DELETE pipeline" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#show' do
        pact_uri '../contracts/project/pipeline/show/pipelines#show-delete_pipeline.json'
      end
    end
  end
end
