# frozen_string_literal: true

RSpec.describe QA::Runtime::API::Client do
  describe "initialization" do
    it "defaults to :gitlab address" do
      expect(described_class.new(personal_access_token: "token").address).to eq :gitlab
    end

    it "uses specified inputs" do
      client = described_class.new("http:///example.com", personal_access_token: "token")

      expect(client.address).to eq "http:///example.com"
      expect(client.personal_access_token).to eq "token"
    end
  end
end
