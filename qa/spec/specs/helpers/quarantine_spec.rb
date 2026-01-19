# frozen_string_literal: true

require 'rspec/core/sandbox'
require 'gitlab_quality/test_tooling'
# Extension for GitlabQuality::TestTooling::TestQuarantine::QuarantineFormatter
require_relative '../../../qa/specs/helpers/quarantine_formatter_extension'

RSpec.describe GitlabQuality::TestTooling::TestQuarantine::QuarantineFormatter, feature_category: :tooling do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec

  around do |ex|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.formatter = GitlabQuality::TestTooling::TestQuarantine::QuarantineFormatter

      # If there is an example-within-an-example, we want to make sure the inner example
      # does not get a reference to the outer example (the real spec) if it calls
      # something like `pending`
      config.before(:context) { RSpec.current_example = nil }

      config.color_mode = :off

      ex.run
    end
  end

  # Tests for GitLab-specific context-based quarantine behavior
  # Generic formatter tests are in gitlab_quality-test_tooling gem
  describe '.skip_or_run_quarantined_tests_or_contexts' do
    context 'with environment set' do
      before do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://staging.gitlab.com')
      end

      context 'no pipeline specified' do
        it 'is skipped when set on contexts or descriptions' do
          group = describe_successfully 'Quarantined in staging', quarantine: { only: { subdomain: :staging } } do
            it('runs in staging') {}
          end

          expect(group.examples.first.execution_result.status).to eq(:pending)
          expect(group.examples.first.execution_result.pending_message)
            .to eq('In quarantine')
        end
      end

      context 'multiple pipelines specified' do
        shared_examples 'skipped in project' do |project|
          before do
            stub_env('CI_PROJECT_NAME', project)
          end

          it "is skipped in #{project}" do
            group = describe_successfully do
              it('does not run in specified projects', quarantine: { only: { pipeline: [:staging, :canary, :production] } }) {}
            end

            expect(group.examples[0].execution_result.status).to eq(:pending)
          end
        end

        it_behaves_like 'skipped in project', 'STAGING'
        it_behaves_like 'skipped in project', 'CANARY'
        it_behaves_like 'skipped in project', 'PRODUCTION'
      end
    end
  end
end
