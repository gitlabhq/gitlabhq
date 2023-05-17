# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  require_relative "../../../spec/contracts/provider/helpers/contract_source_helper"

  namespace :merge_requests do
    Pact::VerificationTask.new(:get_diffs_batch) do |pact|
      pact_helper_location = "pact_helpers/project/merge_requests/show/get_diffs_batch_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    Pact::VerificationTask.new(:get_diffs_metadata) do |pact|
      pact_helper_location = "pact_helpers/project/merge_requests/show/get_diffs_metadata_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    Pact::VerificationTask.new(:get_discussions) do |pact|
      pact_helper_location = "pact_helpers/project/merge_requests/show/get_discussions_helper.rb"

      pact.uri(
        Provider::ContractSourceHelper.contract_location(requester: :rake, file_path: pact_helper_location),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    desc 'Run all merge request contract tests'
    task 'test:merge_requests', :contract_merge_requests do |_t|
      errors = %w[get_diffs_batch get_diffs_metadata get_discussions].each_with_object([]) do |task, err|
        Rake::Task["contracts:merge_requests:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:merge_requests:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
