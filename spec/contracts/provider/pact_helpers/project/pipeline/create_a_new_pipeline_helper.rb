# frozen_string_literal: true

require_relative '../../../spec_helper'
require_relative '../../../states/project/pipeline/new_state'

module Provider
  module CreateNewPipelineHelper
    Pact.service_provider "POST Create a new pipeline" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#new' do
        pact_uri '../contracts/project/pipeline/new/pipelines#new-post_create_a_new_pipeline.json'
      end
    end
  end
end
