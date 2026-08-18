# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::JsonSizeEstimator, feature_category: :observability do
  RSpec::Matchers.define :match_json_bytesize_of do |expected|
    match do |actual|
      actual == expected.to_json.bytesize
    end
  end

  def estimate(object)
    described_class.estimate(object)
  end

  [
    [],
    [[[[]]]],
    [1, "str", 3.14, ["str", { a: -1 }]],
    {},
    { a: {} },
    { a: { b: { c: [1, 2, 3], e: Time.now, f: nil } } },
    { 100 => 500 },
    { '狸' => '狸' },
    nil
  ].each do |example|
    it { expect(estimate(example)).to match_json_bytesize_of(example) }
  end

  it 'calls #to_s on unknown object' do
    klass = Class.new do
      def to_s
        'hello'
      end
    end

    expect(estimate(klass.new)).to match_json_bytesize_of(klass.new.to_s) # "hello"
  end

  describe 'early abort with max_size' do
    it 'returns estimate when under max_size' do
      data = { a: 1, b: 2 }
      actual_size = data.to_json.bytesize

      expect(described_class.estimate(data, max_size: actual_size + 10)).to eq(actual_size)
    end

    it 'raises SizeExceededError when estimate exceeds max_size' do
      large_data = { a: 'x' * 100, b: 'y' * 100 }

      expect { described_class.estimate(large_data, max_size: 50) }
        .to raise_error(described_class::SizeExceededError, /Estimated JSON size .* exceeds limit \(50\)/)
    end

    it 'aborts early during nested object processing' do
      # Create nested structure that would be large when fully processed
      nested_data = {
        level1: {
          level2: {
            level3: 'x' * 1000
          }
        }
      }

      expect { described_class.estimate(nested_data, max_size: 10) }
        .to raise_error(described_class::SizeExceededError)
    end

    it 'aborts early during array processing' do
      large_array = ['x' * 100] * 10

      expect { described_class.estimate(large_array, max_size: 50) }
        .to raise_error(described_class::SizeExceededError)
    end

    it 'works without max_size parameter (backward compatibility)' do
      data = { a: 1, b: 2 }

      expect(described_class.estimate(data)).to match_json_bytesize_of(data)
    end

    it 'does not double-count nested sizes when checking the limit' do
      data = { a: { b: 'xxxxx' } }
      actual_size = data.to_json.bytesize

      # The running total must track the real JSON size, not an inflated one, so
      # a structure that fits under the limit is not aborted prematurely.
      expect(described_class.estimate(data, max_size: actual_size)).to eq(actual_size)
      expect { described_class.estimate(data, max_size: actual_size - 1) }
        .to raise_error(described_class::SizeExceededError)
    end
  end
end
