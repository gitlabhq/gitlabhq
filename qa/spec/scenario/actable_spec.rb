# frozen_string_literal: true

RSpec.describe QA::Scenario::Actable do
  subject do
    Class.new do
      include QA::Scenario::Actable

      attr_accessor :something

      def do_something(arg = nil)
        "some#{arg}"
      end
    end
  end

  describe '.act' do
    it 'provides means to run steps' do
      result = subject.act { do_something }

      expect(result).to eq 'some'
    end

    it 'supports passing variables' do
      result = subject.act('thing') do |variable|
        do_something(variable)
      end

      expect(result).to eq 'something'
    end

    it 'returns value from the last method' do
      result = subject.act { 'test' }

      expect(result).to eq 'test'
    end
  end

  describe '.perform' do
    it 'makes it possible to pass binding' do
      variable = 'something'

      result = subject.perform do |object|
        object.something = variable
      end

      expect(result).to eq 'something'
    end
  end
end
