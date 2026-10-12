# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TruncateSourceFilter do
  include FilterSpecHelper

  let(:short_text) { 'foo' * 10 }
  let(:long_text) { ([short_text] * 10).join(' ') }

  before do
    stub_const("#{described_class}::CHARACTER_COUNT_LIMIT", 50)
    stub_const("#{described_class}::USER_MSG_LIMIT", 20)
  end

  context 'when markdown belongs to a blob' do
    it 'does nothing when limit is unspecified' do
      output = filter(long_text, text_source: :blob)

      expect(output).to eq(long_text)
    end

    it 'truncates normally when limit specified' do
      truncated = 'foofoof...'

      output = filter(long_text, text_source: :blob, limit: 10)

      expect(output).to eq(truncated)
    end
  end

  context 'when markdown belongs to a field (non-blob)' do
    it 'does nothing when limit is greater' do
      output = filter(long_text, limit: 1.megabyte)

      expect(output).to eq(long_text)
    end

    it 'truncates to the default when limit is unspecified' do
      stub_const("#{described_class}::USER_MSG_LIMIT", 200)
      truncated = 'foofoofoofoofoofoofoofoofoofoo foofoofoofoofoof...'

      output = filter(long_text)

      expect(output).to eq(truncated)
    end

    it 'prepends the user message' do
      truncated = <<~TEXT
        _The text is longer than 50 characters and has been visually truncated._

        foofoofoofoofoofoofoofoofoofoo foofoofoofoofoof...
      TEXT

      output = filter(long_text)

      expect(output).to eq(truncated.strip)
    end

    it 'does nothing to a short-enough text' do
      output = filter(short_text, limit: short_text.bytesize)

      expect(output).to eq(short_text)
    end

    it 'truncates UTF-8 text by bytes, on a character boundary' do
      utf8_text = '日本語の文字が大きい'
      truncated = '日...'

      expect(filter(utf8_text, limit: truncated.bytesize)).to eq(truncated)
      expect(filter(utf8_text, limit: utf8_text.bytesize)).to eq(utf8_text)
      expect(filter(utf8_text, limit: utf8_text.mb_chars.size)).not_to eq(utf8_text)
    end
  end
end
