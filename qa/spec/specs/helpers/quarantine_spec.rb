# frozen_string_literal: true

require 'rspec/core/sandbox'

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
  include QA::Specs::Helpers::RSpec

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

        context 'no pipeline specified' do
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

        context 'multiple pipelines specified' do
          shared_examples 'skipped in project' do |project|
            before do
              stub_env('CI_PROJECT_NAME', project)
              described_class.configure_rspec
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
end
