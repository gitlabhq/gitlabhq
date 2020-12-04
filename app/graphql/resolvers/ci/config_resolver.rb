# frozen_string_literal: true

module Resolvers
  module Ci
    class ConfigResolver < BaseResolver
      type Types::Ci::Config::ConfigType, null: true

      argument :content, GraphQL::STRING_TYPE,
               required: true,
               description: 'Contents of .gitlab-ci.yml'

      def resolve(content:)
        result = ::Gitlab::Ci::YamlProcessor.new(content).execute

        response = if result.errors.empty?
                     {
                       status: :valid,
                       errors: [],
                       stages: make_stages(result.jobs)
                     }
                   else
                     {
                       status: :invalid,
                       errors: result.errors
                     }
                   end

        response.merge(merged_yaml: result.merged_yaml)
      end

      private

      def make_jobs(config_jobs)
        config_jobs.map do |job_name, job|
          {
            name: job_name,
            stage: job[:stage],
            group_name: CommitStatus.new(name: job_name).group_name,
            needs: job.dig(:needs, :job) || []
          }
        end
      end

      def make_groups(job_data)
        jobs = make_jobs(job_data)

        jobs_by_group = jobs.group_by { |job| job[:group_name] }
        jobs_by_group.map do |name, jobs|
          { jobs: jobs, name: name, stage: jobs.first[:stage], size: jobs.size }
        end
      end

      def make_stages(jobs)
        make_groups(jobs)
          .group_by { |group| group[:stage] }
          .map { |name, groups| { name: name, groups: groups } }
      end
    end
  end
end
