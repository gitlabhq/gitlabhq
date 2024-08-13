# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvBuilder::Stream do
  let(:event_1) { double(title: 'Added salt', description: 'A teaspoon') }
  let(:event_2) { double(title: 'Added sugar', description: 'Just a pinch') }
  let(:fake_relation) { described_class::FakeRelation.new([event_1, event_2]) }

  subject(:builder) { described_class.new(fake_relation, { 'Title' => 'title', 'Description' => 'description' }) }

  describe '#render' do
    before do
      stub_const("#{described_class}::FakeRelation", Array)

      described_class::FakeRelation.class_eval do
        def find_each(&block)
          each(&block)
        end
      end
    end

    it 'returns a lazy enumerator' do
      expect(builder.render).to be_an(Enumerator::Lazy)
    end

    it 'returns all rows up to default max value' do
      expect(builder.render.to_a).to eq(
        [
          "Title,Description\n",
          "Added salt,A teaspoon\n",
          "Added sugar,Just a pinch\n"
        ])
    end

    it 'truncates to max rows' do
      expect(builder.render(1).to_a).to eq(
        [
          "Title,Description\n",
          "Added salt,A teaspoon\n"
        ])
    end
  end
end
