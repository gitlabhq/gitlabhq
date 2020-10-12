# frozen_string_literal: true

require 'rspec/core/sandbox'

# We need a reporter for internal tests that's different from the reporter for
# external tests otherwise the results will be mixed up. We don't care about
# most reporting, but we do want to know if a test fails
class RaiseOnFailuresReporter < RSpec::Core::NullReporter
  def self.example_failed(example)
    raise example.exception
  end
end

# We use an example group wrapper to prevent the state of internal tests
# expanding into the global state
# See: https://github.com/rspec/rspec-core/issues/2603
def describe_successfully(*args, &describe_body)
  example_group    = RSpec.describe(*args, &describe_body)
  ran_successfully = example_group.run RaiseOnFailuresReporter
  expect(ran_successfully).to eq true
  example_group
end

RSpec.configure do |c|
  c.around do |ex|
    RSpec::Core::Sandbox.sandboxed do |config|
      # If there is an example-within-an-example, we want to make sure the inner example
      # does not get a reference to the outer example (the real spec) if it calls
      # something like `pending`
      config.before(:context) { RSpec.current_example = nil }

      config.color_mode = :off

      ex.run
    end
  end
end

RSpec.describe QA::Specs::Helpers::Quarantine do
  include Helpers::StubENV

  describe '.skip_or_run_quarantined_contexts' do
    context 'with no tag focused' do
      before do
        described_class.configure_rspec
      end

      it 'skips before hooks of quarantined contexts' do
        executed_hooks = []

        group = describe_successfully('quarantine', :quarantine) do
          before(:all) do
            executed_hooks << :before_all
          end
          before do
            executed_hooks << :before
          end
          example {}
        end

        expect(executed_hooks).to eq []
        expect(group.descendant_filtered_examples.first.execution_result.status).to eq(:pending)
        expect(group.descendant_filtered_examples.first.execution_result.pending_message)
          .to eq('In quarantine')
      end

      it 'executes before hooks of non-quarantined contexts' do
        executed_hooks = []

        group = describe_successfully do
          before(:all) do
            executed_hooks << :before_all
          end
          before do
            executed_hooks << :before
          end
          example {}
        end

        expect(executed_hooks).to eq [:before_all, :before]
        expect(group.descendant_filtered_examples.first.execution_result.status).to eq(:passed)
      end
    end

    context 'with :quarantine focused' do
      before do
        described_class.configure_rspec
        RSpec.configure do |c|
          c.filter_run :quarantine
        end
      end

      it 'executes before hooks of quarantined contexts' do
        executed_hooks = []

        group = describe_successfully('quarantine', :quarantine) do
          before(:all) do
            executed_hooks << :before_all
          end
          before do
            executed_hooks << :before
          end
          example {}
        end

        expect(executed_hooks).to eq [:before_all, :before]
        expect(group.descendant_filtered_examples.first.execution_result.status).to eq(:passed)
      end

      it 'skips before hooks of non-quarantined contexts' do
        executed_hooks = []

        group = describe_successfully do
          before(:all) do
            executed_hooks << :before_all
          end
          before do
            executed_hooks << :before
          end
          example {}
        end

        expect(executed_hooks).to eq []
        expect(group.descendant_filtered_examples.first).to be_nil
      end
    end
  end

  describe '.skip_or_run_quarantined_tests_or_contexts' do
    context 'with no tag focused' do
      before do
        described_class.configure_rspec
      end

      it 'skips quarantined tests' do
        group = describe_successfully do
          it('is pending', :quarantine) {}
        end

        expect(group.examples.first.execution_result.status).to eq(:pending)
        expect(group.examples.first.execution_result.pending_message)
          .to eq('In quarantine')
      end

      it 'executes non-quarantined tests' do
        group = describe_successfully do
          example {}
        end

        expect(group.examples.first.execution_result.status).to eq(:passed)
      end

      context 'with environment set' do
        before do
          QA::Runtime::Scenario.define(:gitlab_address, 'https://staging.gitlab.com')
          described_class.configure_rspec
        end

        it 'is skipped when set on contexts or descriptions' do
          group = describe_successfully 'Quarantined in staging', quarantine: { only: { subdomain: :staging } } do
            it('runs in staging') {}
          end

          expect(group.examples.first.execution_result.status).to eq(:pending)
          expect(group.examples.first.execution_result.pending_message)
            .to eq('In quarantine')
        end

        it 'is skipped only in staging' do
          group = describe_successfully do
            it('skipped in staging', quarantine: { only: { subdomain: :staging } }) {}
            it('runs in staging', quarantine: { only: :production }) {}
            it('skipped in staging also', quarantine: { only: { subdomain: %i[release staging] } }) {}
            it('runs in any env') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:pending)
          expect(group.examples[1].execution_result.status).to eq(:passed)
          expect(group.examples[2].execution_result.status).to eq(:pending)
          expect(group.examples[3].execution_result.status).to eq(:passed)
        end
      end

      context 'quarantine message' do
        shared_examples 'test with quarantine message' do |quarantine_tag|
          it 'outputs the quarantine message' do
            group = describe_successfully do
              it('is quarantined', quarantine: quarantine_tag) {}
            end

            expect(group.examples.first.execution_result.pending_message)
              .to eq('In quarantine : for a reason')
          end
        end

        it_behaves_like 'test with quarantine message', 'for a reason'

        it_behaves_like 'test with quarantine message', {
          issue: 'for a reason',
          environment: [:nightly, :staging]
        }
      end
    end

    context 'with :quarantine focused' do
      before do
        described_class.configure_rspec
        RSpec.configure do |c|
          c.filter_run :quarantine
        end
      end

      it 'executes quarantined tests' do
        group = describe_successfully do
          it('passes', :quarantine) {}
        end

        expect(group.examples.first.execution_result.status).to eq(:passed)
      end

      it 'ignores non-quarantined tests' do
        group = describe_successfully do
          example {}
        end

        expect(group.examples.first.execution_result.status).to be_nil
      end
    end

    context 'with a non-quarantine tag focused' do
      before do
        described_class.configure_rspec
        RSpec.configure do |c|
          c.filter_run :foo
        end
      end

      it 'ignores non-quarantined non-focused tests' do
        group = describe_successfully do
          example {}
        end

        expect(group.examples.first.execution_result.status).to be_nil
      end

      it 'executes non-quarantined focused tests' do
        group = describe_successfully do
          it('passes', :foo) {}
        end

        expect(group.examples.first.execution_result.status).to be(:passed)
      end

      it 'ignores quarantined tests' do
        group = describe_successfully do
          it('is ignored', :quarantine) {}
        end

        expect(group.examples.first.execution_result.status).to be_nil
      end

      it 'skips quarantined focused tests' do
        group = describe_successfully do
          it('is pending', :quarantine, :foo) {}
        end

        expect(group.examples.first.execution_result.status).to be(:pending)
        expect(group.examples.first.execution_result.pending_message)
          .to eq('In quarantine')
      end
    end

    context 'with :quarantine and non-quarantine tags focused' do
      before do
        described_class.configure_rspec
        RSpec.configure do |c|
          c.filter_run :foo, :bar, :quarantine
        end
      end

      it 'ignores non-quarantined non-focused tests' do
        group = describe_successfully do
          example {}
        end

        expect(group.examples.first.execution_result.status).to be_nil
      end

      it 'skips non-quarantined focused tests' do
        group = describe_successfully do
          it('is pending', :foo) {}
        end

        expect(group.examples.first.execution_result.status).to be(:pending)
        expect(group.examples.first.execution_result.pending_message)
          .to eq('Only running tests tagged with :quarantine and any of [:bar, :foo]')
      end

      it 'skips quarantined non-focused tests' do
        group = describe_successfully do
          it('is pending', :quarantine) {}
        end

        expect(group.examples.first.execution_result.status).to be(:pending)
      end

      it 'executes quarantined focused tests' do
        group = describe_successfully do
          it('passes', :quarantine, :foo) {}
        end

        expect(group.examples.first.execution_result.status).to be(:passed)
      end
    end
  end

  describe 'running against specific environments or pipelines' do
    before do
      QA::Runtime::Scenario.define(:gitlab_address, 'https://staging.gitlab.com')
      described_class.configure_rspec
    end

    describe 'description and context blocks' do
      context 'with environment set' do
        it 'can apply to contexts or descriptions' do
          group = describe_successfully 'Runs in staging', only: { subdomain: :staging } do
            it('runs in staging') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:passed)
        end
      end

      context 'with different environment set' do
        before do
          QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.com')
          described_class.configure_rspec
        end

        it 'does not run against production' do
          group = describe_successfully 'Runs in staging', :something, only: { subdomain: :staging } do
            it('runs in staging') {}
          end

          expect(group.examples[0].execution_result.status).to eq(:pending)
        end
      end
    end

    it 'runs only in staging' do
      group = describe_successfully do
        it('runs in staging', only: { subdomain: :staging }) {}
        it('doesnt run in staging', only: :production) {}
        it('runs in staging also', only: { subdomain: %i[release staging] }) {}
        it('runs in any env') {}
      end

      expect(group.examples[0].execution_result.status).to eq(:passed)
      expect(group.examples[1].execution_result.status).to eq(:pending)
      expect(group.examples[2].execution_result.status).to eq(:passed)
      expect(group.examples[3].execution_result.status).to eq(:passed)
    end

    context 'custom env' do
      before do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://release.gitlab.net')
      end

      it 'runs on a custom environment' do
        group = describe_successfully do
          it('runs on release gitlab net', only: { tld: '.net', subdomain: :release, domain: 'gitlab' } ) {}
          it('does not run on release', only: :production ) {}
        end

        expect(group.examples.first.execution_result.status).to eq(:passed)
        expect(group.examples.last.execution_result.status).to eq(:pending)
      end
    end

    context 'production' do
      before do
        QA::Runtime::Scenario.define(:gitlab_address, 'https://gitlab.com/')
      end

      it 'runs on production' do
        group = describe_successfully do
          it('runs on prod', only: :production ) {}
          it('does not run in prod', only: { subdomain: :staging }) {}
          it('runs in prod and staging', only: { subdomain: /(staging.)?/, domain: 'gitlab' }) {}
        end

        expect(group.examples[0].execution_result.status).to eq(:passed)
        expect(group.examples[1].execution_result.status).to eq(:pending)
        expect(group.examples[2].execution_result.status).to eq(:passed)
      end
    end

    it 'outputs a message for invalid environments' do
      group = describe_successfully do
        it('will skip', only: :production) {}
      end

      expect(group.examples.first.execution_result.pending_message).to match(/[Tt]est.*not compatible.*environment/)
    end

    context 'with pipeline constraints' do
      context 'without CI_PROJECT_NAME set' do
        before do
          stub_env('CI_PROJECT_NAME', nil)
          described_class.configure_rspec
        end

        it 'runs on any pipeline' do
          group = describe_successfully do
            it('runs given a single named pipeline', only: { pipeline: :nightly } ) {}
            it('runs given an array of pipelines', only: { pipeline: [:canary, :not_nightly] }) {}
          end

          aggregate_failures do
            expect(group.examples[0].execution_result.status).to eq(:passed)
            expect(group.examples[1].execution_result.status).to eq(:passed)
          end
        end
      end

      context 'when a pipeline triggered from master runs in gitlab-qa' do
        before do
          stub_env('CI_PROJECT_NAME', 'gitlab-qa')
          described_class.configure_rspec
        end

        it 'runs on master pipelines' do
          group = describe_successfully do
            it('runs on master pipeline given a single pipeline', only: { pipeline: :master } ) {}
            it('runs in master given an array of pipelines', only: { pipeline: [:canary, :master] }) {}
            it('does not run in non-master pipelines', only: { pipeline: [:nightly, :not_nightly, :not_master] } ) {}
          end

          aggregate_failures do
            expect(group.examples[0].execution_result.status).to eq(:passed)
            expect(group.examples[1].execution_result.status).to eq(:passed)
            expect(group.examples[2].execution_result.status).to eq(:pending)
          end
        end
      end

      context 'with CI_PROJECT_NAME set' do
        before do
          stub_env('CI_PROJECT_NAME', 'NIGHTLY')
          described_class.configure_rspec
        end

        it 'runs on designated pipeline' do
          group = describe_successfully do
            it('runs on nightly', only: { pipeline: :nightly } ) {}
            it('does not run in not_nightly', only: { pipeline: :not_nightly } ) {}
            it('runs on nightly given an array', only: { pipeline: [:canary, :nightly] }) {}
            it('does not run in not_nightly given an array', only: { pipeline: [:not_nightly, :canary] }) {}
          end

          aggregate_failures do
            expect(group.examples[0].execution_result.status).to eq(:passed)
            expect(group.examples[1].execution_result.status).to eq(:pending)
            expect(group.examples[2].execution_result.status).to eq(:passed)
            expect(group.examples[3].execution_result.status).to eq(:pending)
          end
        end
      end
    end
  end
end
