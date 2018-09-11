# frozen_string_literal: true

require 'spec_helper'

describe 'Import metrics on development seed' do
  subject { load Rails.root.join('db', 'fixtures', 'development', '99_common_metrics.rb') }

  it "imports all prometheus metrics" do
    expect(PrometheusMetric.common).to be_empty

    subject

    expect(PrometheusMetric.common).not_to be_empty
  end
end
