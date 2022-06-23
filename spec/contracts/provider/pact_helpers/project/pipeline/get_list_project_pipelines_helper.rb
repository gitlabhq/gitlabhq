# frozen_string_literal: true

require_relative '../../../spec_helper'
require_relative '../../../states/project/pipeline/pipelines_state'

module Provider
  module GetListProjectPipelinesHelper
    Pact.service_provider "GET List project pipelines" do
      app { Environments::Test.app }

      honours_pact_with 'Pipelines#index' do
        pact_uri '../contracts/project/project/pipeline/index/pipelines#index-get_list_project_pipelines.json'
      end
    end
  end
end
