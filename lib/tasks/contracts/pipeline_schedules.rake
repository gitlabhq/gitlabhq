# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  require_relative "../../../spec/contracts/provider/helpers/contract_source_helper"

  namespace :pipeline_schedules do
    Pact::VerificationTask.new(:update_pipeline_schedule) do |pact|
      pact.uri(
        Provider::ContractSourceHelper.contract_location(:UPDATE_PIPELINE_SCHEDULE, :rake),
        pact_helper: "#{provider}/pact_helpers/project/pipeline_schedule/edit/update_pipeline_schedule_helper.rb"
      )
    end

    desc 'Run all pipeline schedule contract tests'
    task 'test:pipeline_schedules', :contract_pipeline_schedules do |_t, arg|
      errors = %w[
        update_pipeline_schedule
      ].each_with_object([]) do |task, err|
        Rake::Task["contracts:pipeline_schedules:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:pipeline_schedule:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
