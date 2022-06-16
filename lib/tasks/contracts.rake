# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

contracts = File.expand_path('../../spec/contracts', __dir__)
provider = File.expand_path('provider', contracts)

# rubocop:disable Rails/RakeEnvironment
namespace :contracts do
  namespace :mr do
    Pact::VerificationTask.new(:diffs_batch) do |pact|
      pact.uri(
        "#{contracts}/contracts/project/merge_request/show/mergerequest#show-merge_request_diffs_batch_endpoint.json",
        pact_helper: "#{provider}/pact_helpers/project/merge_request/diffs_batch_helper.rb"
      )
    end

    Pact::VerificationTask.new(:diffs_metadata) do |pact|
      pact.uri(
        "#{contracts}/contracts/project/merge_request/show/" \
          "mergerequest#show-merge_request_diffs_metadata_endpoint.json",
        pact_helper: "#{provider}/pact_helpers/project/merge_request/diffs_metadata_helper.rb"
      )
    end

    Pact::VerificationTask.new(:discussions) do |pact|
      pact.uri(
        "#{contracts}/contracts/project/merge_request/show/mergerequest#show-merge_request_discussions_endpoint.json",
        pact_helper: "#{provider}/pact_helpers/project/merge_request/discussions_helper.rb"
      )
    end

    desc 'Run all merge request contract tests'
    task 'test:merge_request', :contract_mr do |_t, arg|
      raise(ArgumentError, 'Merge request contract tests require contract_mr to be set') unless arg[:contract_mr]

      ENV['CONTRACT_MR'] = arg[:contract_mr]
      errors = %w[metadata discussions diffs].each_with_object([]) do |task, err|
        Rake::Task["contracts:mr:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:mr:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
# rubocop:enable Rails/RakeEnvironment
