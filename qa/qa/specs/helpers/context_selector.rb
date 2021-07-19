# frozen_string_literal: true

require 'rspec/core'

module QA
  module Specs
    module Helpers
      module ContextSelector
        extend self

        def configure_rspec
          ::RSpec.configure do |config|
            config.before do |example|
              if example.metadata.key?(:only)
                skip('Test is not compatible with this environment or pipeline') unless ContextSelector.context_matches?(example.metadata[:only])
              elsif example.metadata.key?(:except)
                skip('Test is excluded in this job') if ContextSelector.except?(example.metadata[:except])
              end
            end
          end
        end

        def except?(*options)
          return false if Runtime::Env.ci_job_name.blank? && options.any? { |o| o.is_a?(Hash) && o[:job].present? }
          return false if Runtime::Env.ci_project_name.blank? && options.any? { |o| o.is_a?(Hash) && o[:pipeline].present? }
          return false if Runtime::Scenario.attributes[:gitlab_address].blank?

          context_matches?(*options)
        end

        def context_matches?(*options)
          return false unless Runtime::Scenario.attributes[:gitlab_address]

          opts = {}
          opts[:domain] = '.+'
          opts[:tld] = '.com'

          uri = URI(Runtime::Scenario.gitlab_address)

          options.each do |option|
            opts[:domain] = 'gitlab' if option == :production

            next unless option.is_a?(Hash)

            if option[:pipeline].present?
              return true if Runtime::Env.ci_project_name.blank?

              return pipeline_matches?(option[:pipeline])

            elsif option[:job].present?
              return true if Runtime::Env.ci_job_name.blank?

              return job_matches?(option[:job])

            elsif option[:subdomain].present?
              opts.merge!(option)

              opts[:subdomain] = case option[:subdomain]
                                 when Array
                                   "(#{option[:subdomain].join("|")})."
                                 when Regexp
                                   option[:subdomain]
                                 else
                                   "(#{option[:subdomain]})."
                                 end
            end
          end

          uri.host.match?(/^#{opts[:subdomain]}#{opts[:domain]}#{opts[:tld]}$/)
        end

        alias_method :dot_com?, :context_matches?

        def job_matches?(job_patterns)
          Array(job_patterns).any? do |job|
            pattern = job.is_a?(Regexp) ? job : Regexp.new(job)
            pattern = Regexp.new(pattern.source, pattern.options | Regexp::IGNORECASE)
            pattern =~ Runtime::Env.ci_job_name
          end
        end

        def pipeline_matches?(pipeline_to_run_in)
          Array(pipeline_to_run_in).any? { |pipeline| pipeline.to_s.casecmp?(pipeline_from_project_name(Runtime::Env.ci_project_name)) }
        end

        def pipeline_from_project_name(project_name)
          project_name.to_s.start_with?('gitlab-qa') ? Runtime::Env.default_branch : project_name
        end
      end
    end
  end
end
