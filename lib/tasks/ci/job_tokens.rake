# frozen_string_literal: true

return if Rails.env.production?

namespace :ci do
  namespace :job_tokens do
    require_relative './job_tokens_task'

    desc 'CI | Job Tokens | Check if all CI/CD job token allowed endpoints are correctly tagged and documented'
    task check_policies: :environment do
      task_class = Tasks::Ci::JobTokensTask.new
      task_class.check_policies_completeness
      task_class.check_policies_correctness
      task_class.check_docs
    end

    desc 'CI | Job Tokens | Check if all CI/CD job token allowed endpoints are tagged with job_token_policies'
    task check_policies_completeness: :environment do
      Tasks::Ci::JobTokensTask.new.check_policies_completeness
    end

    desc 'CI | Job Tokens | Check if all defined policies for CI/CD job token allowed endpoints are correct'
    task check_policies_correctness: :environment do
      Tasks::Ci::JobTokensTask.new.check_policies_correctness
    end

    desc 'CI | Job Tokens | Check if CI/CD job token allowed endpoints documentation is up to date'
    task check_docs: :environment do
      Tasks::Ci::JobTokensTask.new.check_docs
    end

    desc 'CI | Job Tokens | Compile CI/CD job token allowed endpoints documentation'
    task compile_docs: :environment do
      Tasks::Ci::JobTokensTask.new.compile_docs
    end
  end
end
