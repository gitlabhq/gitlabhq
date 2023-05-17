# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  require_relative "../../../spec/contracts/provider/helpers/contract_source_helper"

  namespace :pipelines do
    Pact::VerificationTask.new(:create_a_new_pipeline) do |pact|
      pact_helper_location = "pact_helpers/project/pipelines/new/post_create_a_new_pipeline_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    Pact::VerificationTask.new(:get_list_project_pipelines) do |pact|
      pact_helper_location = "pact_helpers/project/pipelines/index/get_list_project_pipelines_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    Pact::VerificationTask.new(:get_pipeline_header_data) do |pact|
      pact_helper_location = "pact_helpers/project/pipelines/show/get_pipeline_header_data_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    Pact::VerificationTask.new(:delete_pipeline) do |pact|
      pact_helper_location = "pact_helpers/project/pipelines/show/delete_pipeline_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    desc 'Run all pipeline contract tests'
    task 'test:pipelines', :contract_pipelines do |_t|
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
