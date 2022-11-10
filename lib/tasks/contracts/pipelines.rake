# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

contracts = File.expand_path('../../../spec/contracts/contracts/project/pipeline', __dir__)
provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  namespace :pipelines do
    Pact::VerificationTask.new(:create_a_new_pipeline) do |pact|
      pact.uri(
        "#{contracts}/new/pipelines#new-post_create_a_new_pipeline.json",
        pact_helper: "#{provider}/pact_helpers/project/pipeline/index/create_a_new_pipeline_helper.rb"
      )
    end

    Pact::VerificationTask.new(:get_list_project_pipelines) do |pact|
      pact.uri(
        "#{contracts}/index/pipelines#index-get_list_project_pipelines.json",
        pact_helper: "#{provider}/pact_helpers/project/pipeline/index/get_list_project_pipelines_helper.rb"
      )
    end

    Pact::VerificationTask.new(:get_pipeline_header_data) do |pact|
      # pact.uri(
      #   "http://localhost:9292/pacts/provider/GET%20pipeline%20header%20data/consumer/Pipelines%23show/latest",
      #   pact_helper: "#{provider}/pact_helpers/project/pipeline/show/get_pipeline_header_data_helper.rb"
      # )
      pact.uri(
        "#{contracts}/show/pipelines#show-get_pipeline_header_data.json",
         pact_helper: "#{provider}/pact_helpers/project/pipeline/show/get_pipeline_header_data_helper.rb"
      )
    end

    Pact::VerificationTask.new(:delete_pipeline) do |pact|
      pact.uri(
        "#{contracts}/show/pipelines#show-delete_pipeline.json",
        pact_helper: "#{provider}/pact_helpers/project/pipeline/show/delete_pipeline_helper.rb"
      )
    end

    desc 'Run all pipeline contract tests'
    task 'test:pipelines', :contract_pipelines do |_t, arg|
      errors = %w[
        create_a_new_pipeline
        get_list_project_pipelines
        get_pipeline_header_data
        delete_pipeline
      ].each_with_object([]) do |task, err|
        Rake::Task["contracts:pipelines:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:pipelines:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
