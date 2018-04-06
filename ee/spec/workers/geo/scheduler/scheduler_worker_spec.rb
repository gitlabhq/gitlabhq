require 'spec_helper'

describe Geo::Scheduler::SchedulerWorker do
  it 'includes ::Gitlab::Geo::LogHelpers' do
    expect(described_class).to include_module(::Gitlab::Geo::LogHelpers)
  end

  it 'needs many other specs'
end
