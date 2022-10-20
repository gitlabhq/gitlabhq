# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonHelper do
  let(:hash) { { "foo" => "bar" } }
  let(:json) { '{"foo":"bar"}' }

  describe ".json_generate" do
    subject { helper.json_generate(hash) }

    it "generates JSON" do
      expect(subject).to eq(json)
    end

    it "calls the Gitlab::Json class" do
      expect(Gitlab::Json).to receive(:generate).with(hash)

      subject
    end
  end

  describe ".json_parse" do
    subject { helper.json_parse(json) }

    it "parses JSON" do
      expect(subject).to eq(hash)
    end

    it "calls the Gitlab::Json class" do
      expect(Gitlab::Json).to receive(:parse).with(json)

      subject
    end
  end
end
