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

      # Load airborne again to avoid "undefined method `match_expected_default?'" errors
      # that happen because a hook calls a method added via a custom RSpec setting
      # that is removed when the RSpec configuration is sandboxed.
      # If this needs to be changed (e.g., to load other libraries as well), see
      # this discussion for alternative solutions:
      # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/25223#note_143392053
      load 'airborne.rb'

      ex.run
    end
  end
end

describe QA::Specs::Helpers::Quarantine do
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

  describe '.skip_or_run_quarantined_tests' do
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
