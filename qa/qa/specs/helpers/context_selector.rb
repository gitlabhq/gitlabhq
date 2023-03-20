# frozen_string_literal: true

require 'rspec/core'

module QA
  module Specs
    module Helpers
      module ContextSelector
        extend self

        def except?(*options)
          return false if Runtime::Env.ci_job_name.blank? && options.any? { |o| o.is_a?(Hash) && o[:job].present? }
          return false if Runtime::Env.ci_project_name.blank? && options.any? { |o| o.is_a?(Hash) && o[:pipeline].present? }
          return false if Runtime::Scenario.attributes[:gitlab_address].blank?

          context_matches?(*options)
        end

        def context_matches?(*options)
          return false unless Runtime::Scenario.attributes[:gitlab_address]
          return false if Runtime::Scenario.attributes[:test_metadata_only]

          opts = {}
          opts[:domain] = '.+'
          opts[:tld] = opts_tld

          uri = URI(Runtime::Scenario.gitlab_address)

          options.each do |option|
            opts[:domain] = production_domain if option == :production

            next unless option.is_a?(Hash)

            opts.merge!(option)

            if option[:pipeline].present?
              return true if Runtime::Env.ci_project_name.blank?

              return pipeline_matches?(option[:pipeline])

            elsif option[:job].present?
              return true if Runtime::Env.ci_job_name.blank?

              return job_matches?(option[:job])

            elsif option[:subdomain].present?
              opts[:subdomain] = case option[:subdomain]
                                 when Array
                                   "(#{option[:subdomain].join("|")})\\."
                                 when Regexp
                                   option[:subdomain]
                                 else
                                   "(#{option[:subdomain]})\\."
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

        def production_domain
          GitlabEdition.jh? ? 'jihulab' : 'gitlab'
        end

        def opts_tld
          GitlabEdition.jh? ? '(.com|.hk)' : '.com'
        end
      end
    end
  end
end
