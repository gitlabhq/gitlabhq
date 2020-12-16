# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationExperiment::Cache do
  let(:key_name) { 'experiment_name' }
  let(:field_name) { 'abc123' }
  let(:key_field) { [key_name, field_name].join(':') }
  let(:shared_state) { Gitlab::Redis::SharedState }

  around do |example|
    shared_state.with { |r| r.del(key_name) }
    example.run
    shared_state.with { |r| r.del(key_name) }
  end

  it "allows reading, writing and deleting", :aggregate_failures do
    # we test them all together because they are largely interdependent

    expect(subject.read(key_field)).to be_nil
    expect(shared_state.with { |r| r.hget(key_name, field_name) }).to be_nil

    subject.write(key_field, 'value')

    expect(subject.read(key_field)).to eq('value')
    expect(shared_state.with { |r| r.hget(key_name, field_name) }).to eq('value')

    subject.delete(key_field)

    expect(subject.read(key_field)).to be_nil
    expect(shared_state.with { |r| r.hget(key_name, field_name) }).to be_nil
  end

  it "handles the fetch with a block behavior (which is read/write)" do
    expect(subject.fetch(key_field) { 'value1' }).to eq('value1') # rubocop:disable Style/RedundantFetchBlock
    expect(subject.fetch(key_field) { 'value2' }).to eq('value1') # rubocop:disable Style/RedundantFetchBlock
  end

  it "can clear a whole experiment cache key" do
    subject.write(key_field, 'value')
    subject.clear(key: key_field)

    expect(shared_state.with { |r| r.get(key_name) }).to be_nil
  end

  it "doesn't allow clearing a key from the cache that's not a hash (definitely not an experiment)" do
    shared_state.with { |r| r.set(key_name, 'value') }

    expect { subject.clear(key: key_name) }.to raise_error(
      ArgumentError,
      'invalid call to clear a non-hash cache key'
    )
  end

  context "when the :caching_experiments feature is disabled" do
    before do
      stub_feature_flags(caching_experiments: false)
    end

    it "doesn't write to the cache" do
      subject.write(key_field, 'value')

      expect(subject.read(key_field)).to be_nil
    end
  end
end
