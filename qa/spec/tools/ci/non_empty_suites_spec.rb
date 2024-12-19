# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::NonEmptySuites do
  let(:non_empty_suites) { described_class.new(nil) }

  let(:status) { instance_double(Process::Status, success?: true) }

  before do
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(Logger.new(StringIO.new))
    allow(Open3).to receive(:capture3).and_return(["output\n0", "", status])
    allow(Open3).to receive(:capture3)
      .with("bundle exec bin/qa QA::Scenario::Test::Instance::All --count-examples-only --address http://dummy1.test")
      .and_return(["output\n1", "", status])
  end

  it "returns runnable test suites" do
    expect(non_empty_suites.fetch).to eq("QA::Scenario::Test::Instance::All")
  end
end
