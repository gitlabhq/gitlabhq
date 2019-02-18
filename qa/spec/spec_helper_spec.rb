# frozen_string_literal: true

describe 'rspec config tests' do
  let(:group) do
    RSpec.describe do
      shared_examples 'passing tests' do
        example 'not in quarantine' do
        end
        example 'in quarantine', :quarantine do
        end
      end

      context 'default' do
        it_behaves_like 'passing tests'
      end

      context 'foo', :foo do
        it_behaves_like 'passing tests'
      end

      context 'quarantine', :quarantine do
        it_behaves_like 'passing tests'
      end

      context 'bar quarantine', :bar, :quarantine do
        it_behaves_like 'passing tests'
      end
    end
  end

  context 'with no tags focussed' do
    before do
      group.run
    end

    context 'in a context tagged :foo' do
      it 'skips tests in quarantine' do
        context = group.children.find { |c| c.description == "foo" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to eq(2)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('In quarantine')
      end
    end

    context 'in an untagged context' do
      it 'skips tests in quarantine' do
        context = group.children.find { |c| c.description == "default" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to eq(2)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('In quarantine')
      end
    end

    context 'in a context tagged :quarantine' do
      it 'skips all tests' do
        context = group.children.find { |c| c.description == "quarantine" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to eq(2)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('In quarantine')
      end
    end
  end

  context 'with :quarantine focussed' do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = :quarantine
      end

      group.run
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    context 'in an untagged context' do
      it 'only runs quarantined tests' do
        context = group.children.find { |c| c.description == "default" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(1)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)
      end
    end

    context 'in a context tagged :foo' do
      it 'only runs quarantined tests' do
        context = group.children.find { |c| c.description == "foo" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(1)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)
      end
    end

    context 'in a context tagged :quarantine' do
      it 'runs all tests' do
        context = group.children.find { |c| c.description == "quarantine" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)
      end
    end
  end

  context 'with a non-quarantine tag (:foo) focussed' do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = :foo
      end

      group.run
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    context 'in an untagged context' do
      it 'runs no tests' do
        context = group.children.find { |c| c.description == "default" }
        expect(context.descendant_filtered_examples.count).to eq(0)
      end
    end

    context 'in a context tagged :foo' do
      it 'skips quarantined tests' do
        context = group.children.find { |c| c.description == "foo" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('In quarantine')
      end
    end

    context 'in a context tagged :quarantine' do
      it 'runs no tests' do
        context = group.children.find { |c| c.description == "quarantine" }
        expect(context.descendant_filtered_examples.count).to eq(0)
      end
    end
  end

  context 'with :quarantine and a non-quarantine tag (:foo) focussed' do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = { quarantine: true, foo: true }
      end

      group.run
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    context 'in an untagged context' do
      it 'ignores untagged tests and skips tests even if in quarantine' do
        context = group.children.find { |c| c.description == "default" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to eq(1)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
      end
    end

    context 'in a context tagged :foo' do
      it 'only runs quarantined tests' do
        context = group.children.find { |c| c.description == "foo" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
      end
    end

    context 'in a context tagged :quarantine' do
      it 'skips all tests' do
        context = group.children.find { |c| c.description == "quarantine" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
      end
    end

    context 'in a context tagged :bar and :quarantine' do
      it 'skips all tests' do
        context = group.children.find { |c| c.description == "quarantine" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
      end
    end
  end

  context 'with :quarantine and multiple non-quarantine tags focussed' do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = { bar: true, foo: true, quarantine: true }
      end

      group.run
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    context 'in a context tagged :foo' do
      it 'only runs quarantined tests' do
        context = group.children.find { |c| c.description == "foo" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('Only running tests tagged with :quarantine and any of [:bar, :foo]')
      end
    end

    context 'in a context tagged :quarantine' do
      it 'skips all tests' do
        context = group.children.find { |c| c.description == "quarantine" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('Only running tests tagged with :quarantine and any of [:bar, :foo]')

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:pending)
        expect(ex.execution_result.pending_message).to eq('Only running tests tagged with :quarantine and any of [:bar, :foo]')
      end
    end

    context 'in a context tagged :bar and :quarantine' do
      it 'runs all tests' do
        context = group.children.find { |c| c.description == "bar quarantine" }
        examples = context.descendant_filtered_examples
        expect(examples.count).to be(2)

        ex = examples.find { |e| e.description == "in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)

        ex = examples.find { |e| e.description == "not in quarantine" }
        expect(ex.execution_result.status).to eq(:passed)
      end
    end
  end
end
