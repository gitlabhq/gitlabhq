# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Helpers::Output do
  subject(:helper) do
    Class.new do
      include Gitlab::Orchestrator::Helpers::Output

      def masked_output
        mask_secrets("foo\nbaz\nbar", %w[foo bar])
      end
    end.new
  end

  it "masks secrets in output" do
    expect(helper.masked_output).to eq("*****\nbaz\n*****")
  end
end
