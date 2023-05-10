# frozen_string_literal: true

require 'rspec/core/sandbox'

RSpec.describe QA::Specs::Helpers::FeatureFlag do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec

  around do |ex|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.add_formatter QA::Support::Formatters::ContextFormatter
      config.add_formatter QA::Support::Formatters::QuarantineFormatter
      config.add_formatter QA::Support::Formatters::FeatureFlagFormatter

      # If there is an example-within-an-example, we want to make sure the inner example
      # does not get a reference to the outer example (the real spec) if it calls
      # something like `pending`
      config.before(:context) { RSpec.current_example = nil }

      config.color_mode = :off

      ex.run
    end
  end

  describe '.skip_or_run_feature_flag_tests_or_contexts' do
    shared_examples 'runs with given feature flag metadata' do |metadata|
      it do
        group = describe_successfully 'Feature flag test', feature_flag: metadata do
          it('passes') {}
        end

        expect(group.examples.first.execution_result.status).to eq(:passed)
      end
    end

    shared_examples 'skips with given feature flag metadata' do |metadata|
      it do
        group = describe_successfully 'Feature flag test', feature_flag: metadata do
          it('is skipped') {}
        end

        expect(group.examples.first.execution_result.status).to eq(:pending)
      end
    end

    context 'when run on staging' do
      before(:context) do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://staging.gitlab.com')
      end

      context 'when no scope is defined' do
        it_behaves_like 'runs with given feature flag metadata', { name: 'no_scope_ff' }

        it 'is skipped if quarantine tag is also applied' do
          group = describe_successfully(
            'Feature flag with no scope',
            feature_flag: { name: 'quarantine_with_ff' },
            quarantine: {
              issue: 'https://gitlab.com/test-group/test/-/issues/123',
              type: 'bug'
            }
          ) do
            it('is skipped') {}
          end

          expect(group.examples.first.execution_result.status).to eq(:pending)
        end
      end

      it_behaves_like 'runs with given feature flag metadata', { name: 'actor_ff', scope: :project }

      it_behaves_like 'skips with given feature flag metadata', { name: 'global_ff', scope: :global }

      context 'when should be skipped in a specific job' do
        before do
          stub_env('CI_JOB_NAME', 'job-to-skip')
        end

        it 'is skipped for that job' do
          group = describe_successfully(
            'Test should be skipped',
            feature_flag: { name: 'skip_job_ff' },
            except: { job: 'job-to-skip' }
          ) do
            it('does not run on staging in specified job') {}
          end

          expect(group.examples.first.execution_result.status).to eq(:pending)
        end
      end

      context 'when should only run in a specific job' do
        before do
          stub_env('CI_JOB_NAME', 'job-to-run')
        end

        it 'is run for that job' do
          group = describe_successfully(
            'Test should run',
            feature_flag: { name: 'run_job_ff' },
            only: { job: 'job-to-run' }
          ) do
            it('runs on staging in specified job') {}
          end

          expect(group.examples.first.execution_result.status).to eq(:passed)
        end

        it 'skips if test is set to only run in a job different from current CI job' do
          group = describe_successfully(
            'Test should be skipped',
            feature_flag: { name: 'skip_job_ff' },
            only: { job: 'other-job' }
          ) do
            it('does not run on staging in specified job') {}
          end

          expect(group.examples.first.execution_result.status).to eq(:pending)
        end
      end
    end

    context 'when run on production' do
      before do
        allow(GitlabEdition).to receive(:jh?).and_return(false)
      end

      before(:context) do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.com')
      end

      context 'when no scope is defined' do
        it_behaves_like 'skips with given feature flag metadata', { name: 'no_scope_ff' }

        context 'for only one test in the example group' do
          it 'only skips specified test and runs all others' do
            group = describe_successfully 'Feature flag set for one test' do
              it('is skipped', feature_flag: { name: 'single_test_ff' }) {}
              it('passes') {}
            end

            expect(group.examples[0].execution_result.status).to eq(:pending)
            expect(group.examples[1].execution_result.status).to eq(:passed)
          end
        end
      end

      it_behaves_like 'skips with given feature flag metadata', { name: 'actor_ff', scope: :project }

      it_behaves_like 'skips with given feature flag metadata', { name: 'global_ff', scope: :global }
    end

    context 'when run on jh production mainland' do
      before do
        allow(GitlabEdition).to receive(:jh?).and_return(true)
      end

      before(:context) do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://jihulab.com')
      end

      context 'when no scope is defined' do
        it_behaves_like 'skips with given feature flag metadata', { name: 'no_scope_ff' }

        context 'for only one test in the example group' do
          it 'only skips specified test and runs all others' do
            group = describe_successfully 'Feature flag set for one test' do
              it('is skipped', feature_flag: { name: 'single_test_ff' }) {}
              it('passes') {}
            end

            expect(group.examples[0].execution_result.status).to eq(:pending)
            expect(group.examples[1].execution_result.status).to eq(:passed)
          end
        end
      end

      it_behaves_like 'skips with given feature flag metadata', { name: 'actor_ff', scope: :project }

      it_behaves_like 'skips with given feature flag metadata', { name: 'global_ff', scope: :global }
    end

    context 'when run on jh production hk' do
      before do
        allow(GitlabEdition).to receive(:jh?).and_return(true)
      end

      before(:context) do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.hk')
      end

      context 'when no scope is defined' do
        it_behaves_like 'skips with given feature flag metadata', { name: 'no_scope_ff' }

        context 'for only one test in the example group' do
          it 'only skips specified test and runs all others' do
            group = describe_successfully 'Feature flag set for one test' do
              it('is skipped', feature_flag: { name: 'single_test_ff' }) {}
              it('passes') {}
            end

            expect(group.examples[0].execution_result.status).to eq(:pending)
            expect(group.examples[1].execution_result.status).to eq(:passed)
          end
        end
      end

      it_behaves_like 'skips with given feature flag metadata', { name: 'actor_ff', scope: :project }

      it_behaves_like 'skips with given feature flag metadata', { name: 'global_ff', scope: :global }
    end

    context 'when run on pre' do
      before(:context) do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://pre.gitlab.com')
      end

      context 'for only one test in the example group' do
        it 'only skips specified test and runs all others' do
          group = describe_successfully 'Feature flag set for one test' do
            it('is skipped', feature_flag: { name: 'single_test_ff', scope: :group }) {}
            it('passes') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:pending)
          expect(group.examples[1].execution_result.status).to eq(:passed)
        end
      end

      it_behaves_like 'skips with given feature flag metadata', { name: 'actor_ff', scope: :project }

      it_behaves_like 'skips with given feature flag metadata', { name: 'global_ff', scope: :global }
    end

    # The nightly package job, for example, does not run against a live environment with
    # a defined gitlab_address. In this case, feature_flag tag logic can be safely ignored
    context 'when run without a gitlab address specified' do
      before(:context) do
        QA::Runtime::Scenario.define(:gitlab_address, nil)
      end

      it_behaves_like 'runs with given feature flag metadata', { name: 'no_scope_ff' }

      it_behaves_like 'runs with given feature flag metadata', { name: 'actor_ff', scope: :project }

      it_behaves_like 'runs with given feature flag metadata', { name: 'global_ff', scope: :global }
    end
  end
end
