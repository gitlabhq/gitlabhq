# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

contracts = File.expand_path('../../../spec/contracts', __dir__)
provider = File.expand_path('provider', contracts)

# rubocop:disable Rails/RakeEnvironment
namespace :contracts do
  namespace :pipelines do
    Pact::VerificationTask.new(:get_list_project_pipelines) do |pact|
      pact.uri(
        "#{contracts}/contracts/project/pipeline/index/pipelines#index-get_list_project_pipelines.json",
        pact_helper: "#{provider}/pact_helpers/project/pipeline/get_list_project_pipelines_helper.rb"
      )
    end

    Pact::VerificationTask.new(:get_pipeline_header_data) do |pact|
      pact.uri(
        "#{contracts}/contracts/project/pipeline/show/pipelines#show-get_pipeline_header_data.json",
        pact_helper: "#{provider}/pact_helpers/project/pipeline/get_pipeline_header_data_helper.rb"
      )
    end

    desc 'Run all pipeline contract tests'
    task 'test:pipelines', :contract_mr do |_t, arg|
      errors = %w[get_list_project_pipelines get_pipeline_header_data].each_with_object([]) do |task, err|
        Rake::Task["contracts:pipelines:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:pipelines:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
# rubocop:enable Rails/RakeEnvironment
