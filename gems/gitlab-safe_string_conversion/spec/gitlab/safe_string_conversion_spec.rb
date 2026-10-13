# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::SafeStringConversion, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:small_string) { "123" }
  let(:large_string) { "1" * (described_class.max_string_size + 1) }

  describe '.check_string_size!' do
    it 'allows strings smaller than the limit' do
      expect { described_class.check_string_size!(small_string) }.not_to raise_error
    end

    it 'raises ConversionError for strings larger than the limit' do
      expect do
        described_class.check_string_size!(large_string)
      end.to raise_error(described_class::ConversionError)
    end
  end

  describe 'String methods' do
    describe 'successful conversions' do
      where(:method, :value, :expected_result) do
        [
          [:to_i, "123", 123],
          [:to_r, "123", Rational(123)],
          [:to_c, "123", Complex(123)]
        ]
      end

      with_them do
        it "correctly handles the conversion" do
          expect(value.send(method)).to eq(expected_result)
        end
      end
    end

    describe 'error cases' do
      where(:method, :expected_result) do
        [
          [:to_i, described_class::ConversionError],
          [:to_r, described_class::ConversionError],
          [:to_c, described_class::ConversionError]
        ]
      end

      with_them do
        it "raises error for large strings" do
          expect { large_string.send(method) }.to raise_error(expected_result)
        end
      end
    end
  end

  describe 'Kernel methods' do
    describe 'successful conversions' do
      where(:method, :value, :expected_result) do
        [
          [:Integer, "123", 123],
          [:Rational, "123", Rational(123)],
          [:Complex, "123", Complex(123)],
          [:Integer, 123.45, 123],
          [:Rational, 123, Rational(123)],
          [:Complex, 123, Complex(123)]
        ]
      end

      with_them do
        it "correctly handles the conversion" do
          expect(send(method, value)).to eq(expected_result)
        end
      end
    end

    describe 'error cases' do
      where(:method, :expected_result) do
        [
          [:Integer, described_class::ConversionError],
          [:Rational, described_class::ConversionError],
          [:Complex, described_class::ConversionError]
        ]
      end

      with_them do
        it "raises error for large strings" do
          expect { send(method, large_string) }.to raise_error(expected_result)
        end
      end
    end
  end

  describe 'configuration' do
    it 'allows changing the max_string_size' do
      original_size = described_class.max_string_size
      begin
        described_class.max_string_size = 10
        expect { "12345678901".to_i }.to raise_error(described_class::ConversionError)
        expect { "1234567890".to_i }.not_to raise_error
      ensure
        described_class.max_string_size = original_size
      end
    end
  end

  describe '.disable_safety' do
    it 'allows large strings to convert inside the block' do
      described_class.disable_safety do
        expect { large_string.to_i }.not_to raise_error
      end
    end

    it 'restores protection after the block' do
      described_class.disable_safety { large_string.to_i }

      expect { large_string.to_i }.to raise_error(described_class::ConversionError)
    end

    it 'restores protection after the block even when it raises' do
      expect do
        described_class.disable_safety { raise 'boom' }
      end.to raise_error('boom')

      expect { large_string.to_i }.to raise_error(described_class::ConversionError)
    end

    it 'keeps the check disabled inside a fiber on the same thread' do
      described_class.disable_safety do
        enumerator = Enumerator.new { |yielder| yielder << large_string.to_i }

        expect { enumerator.next }.not_to raise_error
      end
    end

    it 'only disables the check for the current thread' do
      described_class.disable_safety do
        expect { large_string.to_i }.not_to raise_error

        other_thread_error = nil
        Thread.new do
          large_string.to_i
        rescue described_class::ConversionError => e
          other_thread_error = e
        end.join

        expect(other_thread_error).to be_a(described_class::ConversionError)
      end
    end
  end
end
