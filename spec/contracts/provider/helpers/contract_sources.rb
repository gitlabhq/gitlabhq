# frozen_string_literal: true

module Provider
  module ContractSources
    PACT_BROKER_HOST = "http://localhost:9292/pacts/provider"

    RELATIVE_PATHS = {
      rake: "../../../contracts/contracts/project",
      spec: "../contracts/project"
    }.freeze

    CONTRACT_SOURCES = {
      # MergeRequest#show
      GET_DIFFS_BATCH: {
        broker: "#{PACT_BROKER_HOST}/Merge%20Request%20Diffs%20Batch%20Endpoint/consumer/MergeRequest%23show/latest",
        local: "/merge_request/show/mergerequest#show-merge_request_diffs_batch_endpoint.json"
      },
      GET_DIFFS_METADATA: {
        broker: "#{PACT_BROKER_HOST}/Merge%20Request%20Diffs%20Metadata%20Endpoint/consumer/MergeRequest%23show/latest",
        local: "/merge_request/show/mergerequest#show-merge_request_diffs_metadata_endpoint.json"
      },
      GET_DISCUSSIONS: {
        broker: "#{PACT_BROKER_HOST}/Merge%20Request%20Discussions%20Endpoint/consumer/MergeRequest%23show/latest",
        local: "/merge_request/show/mergerequest#show-merge_request_discussions_endpoint.json"
      },
      # Pipeline#index
      CREATE_A_NEW_PIPELINE: {
        broker: "#{PACT_BROKER_HOST}/POST%20Create%20a%20new%20pipeline/consumer/Pipelines%23new/latest",
        local: "/pipeline/new/pipelines#new-post_create_a_new_pipeline.json"
      },
      GET_LIST_PROJECT_PIPELINE: {
        broker: "#{PACT_BROKER_HOST}/GET%20List%20project%20pipelines/consumer/Pipelines%23index/latest",
        local: "/pipeline/index/pipelines#index-get_list_project_pipelines.json"
      },
      # Pipelines#show
      DELETE_PIPELINE: {
        broker: "#{PACT_BROKER_HOST}/DELETE%20pipeline/consumer/Pipelines%23show/latest",
        local: "/pipeline/show/pipelines#show-delete_pipeline.json"
      },
      GET_PIPELINE_HEADER_DATA: {
        broker: "#{PACT_BROKER_HOST}/GET%20pipeline%20header%20data/consumer/Pipelines%23show/latest",
        local: "/pipeline/show/pipelines#show-get_pipeline_header_data.json"
      },
      # PipelineSchedule#edit
      UPDATE_PIPELINE_SCHEDULE: {
        broker: "#{PACT_BROKER_HOST}/PUT%20Edit%20a%20pipeline%20schedule/consumer/PipelineSchedules%23edit/latest",
        local: "/pipeline_schedule/edit/pipelineschedules#edit-put_edit_a_pipeline_schedule.json"
      }
    }.freeze
  end
end
