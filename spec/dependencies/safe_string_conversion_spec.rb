# frozen_string_literal: true

require 'spec_helper'

# The patch reaches the app only through Bundler's implicit require of the
# gitlab-safe_string_conversion gem line in the Gemfile, and Bundler swallows a
# LoadError on the dash-to-slash fallback, so a broken require would otherwise
# boot fine with the DoS protection silently gone.
RSpec.describe 'string conversion safety in dependencies', feature_category: :instance_resiliency do
  let(:oversized_string) { "1" * (Gitlab::SafeStringConversion.max_string_size + 1) }

  it 'converts strings within the limit' do
    expect("123".to_i).to eq(123)
  end

  it 'raises on an oversized String#to_i' do
    expect { oversized_string.to_i }.to raise_error(Gitlab::SafeStringConversion::ConversionError)
  end

  it 'raises on an oversized Kernel#Integer' do
    expect { Integer(oversized_string) }.to raise_error(Gitlab::SafeStringConversion::ConversionError)
  end
end
