# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

contracts = File.expand_path('../../../spec/contracts/contracts/project/pipeline_schedule', __dir__)
provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  namespace :pipeline_schedules do
    Pact::VerificationTask.new(:update_pipeline_schedule) do |pact|
      pact.uri(
        "#{contracts}/edit/pipelineschedules#edit-put_edit_a_pipeline_schedule.json",
        pact_helper: "#{provider}/pact_helpers/project/pipeline_schedule/update_pipeline_schedule_helper.rb"
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
