# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  require_relative "../../../spec/contracts/provider/helpers/contract_source_helper"

  namespace :pipelines do
    Pact::VerificationTask.new(:create_a_new_pipeline) do |pact|
      pact.uri(
        Provider::ContractSourceHelper.contract_location(:CREATE_A_NEW_PIPELINE, :rake),
        pact_helper: "#{provider}/pact_helpers/project/pipeline/index/create_a_new_pipeline_helper.rb"
      )
    end

    Pact::VerificationTask.new(:get_list_project_pipelines) do |pact|
      pact.uri(
        Provider::ContractSourceHelper.contract_location(:GET_LIST_PROJECT_PIPELINE, :rake),
        pact_helper: "#{provider}/pact_helpers/project/pipeline/index/get_list_project_pipelines_helper.rb"
      )
    end

    Pact::VerificationTask.new(:get_pipeline_header_data) do |pact|
      pact.uri(
        Provider::ContractSourceHelper.contract_location(:GET_PIPELINE_HEADER_DATA, :rake),
        pact_helper: "#{provider}/pact_helpers/project/pipeline/show/get_pipeline_header_data_helper.rb"
      )
    end

    Pact::VerificationTask.new(:delete_pipeline) do |pact|
      pact.uri(
        Provider::ContractSourceHelper.contract_location(:DELETE_PIPELINE, :rake),
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
