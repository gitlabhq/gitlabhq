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

      context 'foo', :foo do
        it_behaves_like 'passing tests'
      end

      context 'default' do
        it_behaves_like 'passing tests'
      end
    end
  end

  context 'default config' do
    it 'tests are skipped if in quarantine' do
      group.run

      foo_context = group.children.find { |c| c.description == "foo" }
      foo_examples = foo_context.descendant_filtered_examples
      expect(foo_examples.count).to eq(2)

      ex = foo_examples.find { |e| e.description == "not in quarantine" }
      expect(ex.execution_result.status).to eq(:passed)

      ex = foo_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('In quarantine')

      default_context = group.children.find { |c| c.description == "default" }
      default_examples = default_context.descendant_filtered_examples
      expect(default_examples.count).to eq(2)

      ex = default_examples.find { |e| e.description == "not in quarantine" }
      expect(ex.execution_result.status).to eq(:passed)

      ex = default_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('In quarantine')
    end
  end

  context "with 'quarantine' tagged" do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = :quarantine
      end
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    it "only quarantined tests are run" do
      group.run

      foo_context = group.children.find { |c| c.description == "foo" }
      foo_examples = foo_context.descendant_filtered_examples
      expect(foo_examples.count).to be(1)

      ex = foo_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:passed)

      default_context = group.children.find { |c| c.description == "default" }
      default_examples = default_context.descendant_filtered_examples
      expect(default_examples.count).to be(1)

      ex = default_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:passed)
    end
  end

  context "with 'foo' tagged" do
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

    it "tests are not run if not tagged 'foo'" do
      default_context = group.children.find { |c| c.description == "default" }
      expect(default_context.descendant_filtered_examples.count).to eq(0)
    end

    it "tests are skipped if in quarantine" do
      foo_context = group.children.find { |c| c.description == "foo" }
      foo_examples = foo_context.descendant_filtered_examples
      expect(foo_examples.count).to eq(2)

      ex = foo_examples.find { |e| e.description == "not in quarantine" }
      expect(ex.execution_result.status).to eq(:passed)

      ex = foo_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('In quarantine')
    end
  end

  context "with 'quarantine' and 'foo' tagged" do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = { quarantine: true, foo: true }
      end
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    it 'of tests tagged foo, only tests in quarantine run' do
      group.run

      foo_context = group.children.find { |c| c.description == "foo" }
      foo_examples = foo_context.descendant_filtered_examples
      expect(foo_examples.count).to eq(2)

      ex = foo_examples.find { |e| e.description == "not in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('Running tests tagged with all of [:quarantine, :foo]')

      ex = foo_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:passed)
    end

    it 'if tests are not tagged they are skipped, even if they are in quarantine' do
      group.run
      default_context = group.children.find { |c| c.description == "default" }
      default_examples = default_context.descendant_filtered_examples
      expect(default_examples.count).to eq(1)

      ex = default_examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('Running tests tagged with all of [:quarantine, :foo]')
    end
  end

  context "with 'foo' and 'bar' tagged" do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = { bar: true, foo: true }
      end
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    it "runs tests tagged either 'foo' or 'bar'" do
      group = RSpec.describe do
        example 'foo', :foo do
        end
        example 'bar', :bar do
        end
        example 'foo and bar', :foo, :bar do
        end
      end

      group.run
      expect(group.examples.count).to eq(3)

      ex = group.examples.find { |e| e.description == "foo" }
      expect(ex.execution_result.status).to eq(:passed)

      ex = group.examples.find { |e| e.description == "bar" }
      expect(ex.execution_result.status).to eq(:passed)

      ex = group.examples.find { |e| e.description == "foo and bar" }
      expect(ex.execution_result.status).to eq(:passed)
    end

    it "skips quarantined tests tagged 'foo' and/or 'bar'" do
      group = RSpec.describe do
        example 'foo in quarantine', :foo, :quarantine do
        end
        example 'foo and bar in quarantine', :foo, :bar, :quarantine do
        end
      end

      group.run
      expect(group.examples.count).to eq(2)

      ex = group.examples.find { |e| e.description == "foo in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('In quarantine')

      ex = group.examples.find { |e| e.description == "foo and bar in quarantine" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('In quarantine')
    end

    it "ignores quarantined tests not tagged either 'foo' or 'bar'" do
      group = RSpec.describe do
        example 'in quarantine', :quarantine do
        end
      end

      group.run

      ex = group.examples.find { |e| e.description == "in quarantine" }
      expect(ex.execution_result.status).to be_nil
    end
  end

  context "with 'foo' and 'bar' and 'quarantined' tagged" do
    before do
      RSpec.configure do |config|
        config.inclusion_filter = { bar: true, foo: true, quarantine: true }
      end
    end
    after do
      RSpec.configure do |config|
        config.inclusion_filter.clear
      end
    end

    it "runs tests tagged 'quarantine' and 'foo' or 'bar'" do
      group = RSpec.describe do
        example 'foo', :foo do
        end
        example 'bar and quarantine', :bar, :quarantine do
        end
        example 'foo and bar', :foo, :bar do
        end
        example 'foo, bar, and quarantine', :foo, :bar, :quarantine do
        end
      end

      group.run
      expect(group.examples.count).to eq(4)

      ex = group.examples.find { |e| e.description == "foo" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('Running tests tagged with all of [:bar, :foo, :quarantine]')

      ex = group.examples.find { |e| e.description == "bar and quarantine" }
      expect(ex.execution_result.status).to eq(:passed)

      ex = group.examples.find { |e| e.description == "foo and bar" }
      expect(ex.execution_result.status).to eq(:pending)
      expect(ex.execution_result.pending_message).to eq('Running tests tagged with all of [:bar, :foo, :quarantine]')

      ex = group.examples.find { |e| e.description == "foo, bar, and quarantine" }
      expect(ex.execution_result.status).to eq(:passed)
    end
  end
end
