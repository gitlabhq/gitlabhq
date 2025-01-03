# frozen_string_literal: true

RSpec.describe QA::Tools::LongRunningSpecReporter do
  include QA::Support::Helpers::StubEnv

  subject(:reporter) { described_class.execute }

  let(:slack_notifier) { instance_double(Slack::Notifier, post: nil) }

  before do
    allow(File).to receive(:read)
      .with(QA::Support::KnapsackReport::FALLBACK_REPORT)
      .and_return(report)
    allow(Slack::Notifier).to receive(:new)
      .with("slack_url", channel: "#quality-reports", username: "Spec Runtime Report")
      .and_return(slack_notifier)

    stub_env("SLACK_WEBHOOK", "slack_url")
  end

  context "without specs exceeding runtime" do
    let(:report) do
      <<~JSON
        {
          "spec.rb": 5,
          "spec_2.rb": 10
        }
      JSON
    end

    it "returns all good message" do
      expect { reporter }.to output("No long running specs detected, all good!\n").to_stdout
    end
  end

  context "with specs exceeding runtime" do
    let(:report) do
      <<~JSON
        {
          "spec.rb": 5.0,
          "spec_2.rb": 320.0
        }
      JSON
    end

    let(:spec) { "spec_2.rb: 5.33 minutes" }

    let(:message) do
      <<~MSG
        Following spec files are exceeding 5 minute runtime threshold!
        Current average spec runtime: 5 seconds.
      MSG
    end

    it "notifies on long running specs" do
      expect { reporter }.to output("#{message}\n#{spec}\n").to_stdout
      expect(slack_notifier).to have_received(:post).with(
        icon_emoji: ":time-out:",
        text: "#{message}\n```#{spec}```"
      )
    end
  end
end
