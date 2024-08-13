# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvBuilder::Gzip do
  let(:event_1) { double(title: 'Added salt', description: 'A teaspoon') }
  let(:event_2) { double(title: 'Added sugar', description: 'Just a pinch') }
  let(:items) { [event_1, event_2] }

  subject(:builder) { described_class.new(items, { 'Title' => 'title', 'Description' => 'description' }) }

  describe '#render' do
    it 'returns yields a tempfile' do
      written_content = nil

      builder.render do |tempfile|
        reader = Zlib::GzipReader.new(tempfile)
        written_content = reader.read.split("\n")
      end

      expect(written_content).to eq(
        [
          "Title,Description",
          "Added salt,A teaspoon",
          "Added sugar,Just a pinch"
        ])
    end

    it 'yields the number of written rows as the second argument' do
      row_count = 0
      builder.render { |_, rows| row_count = rows }

      expect(row_count).to eq(2)
    end

    it 'requires a block' do
      expect { builder.render }.to raise_error(LocalJumpError)
    end
  end
end
