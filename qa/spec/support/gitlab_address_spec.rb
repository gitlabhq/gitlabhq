# frozen_string_literal: true

RSpec.describe QA::Support::GitlabAddress do
  subject(:gitlab_address) { described_class }

  describe ".define_gitlab_address_attribute!" do
    let(:address) { "http://example.com" }

    before do
      allow(QA::Runtime::Scenario).to receive(:define)

      gitlab_address.instance_variable_set(:@initialized, initialized)
      gitlab_address.define_gitlab_address_attribute!(address)
    end

    context "with attribute not initialized" do
      let(:initialized) { nil }

      it "initializes gitlab address attribute", :aggregate_failures do
        expect(QA::Runtime::Scenario).to have_received(:define).with(:gitlab_address, address)
        expect(QA::Runtime::Scenario).to have_received(:define).with(:about_address, "http://about.example.com")
      end
    end

    context "with attribute already initialized" do
      let(:initialized) { true }

      it "skips setting gitlab address attribute" do
        expect(QA::Runtime::Scenario).not_to have_received(:define)
      end
    end
  end

  describe ".address_with_port" do
    context "when fetching address" do
      let(:address) { gitlab_address.address_with_port("http://example.com/relative") }

      it { expect(address).to eq("http://example.com:80/relative") }
    end
  end

  describe ".host_with_port" do
    context "when fetching host with default port" do
      let(:host) { gitlab_address.host_with_port("http://example.com/relative") }

      it { expect(host).to eq("example.com:80/relative") }
    end

    context "when fetching host with default port ommitted" do
      let(:host) { gitlab_address.host_with_port("http://example.com/relative", with_default_port: false) }

      it { expect(host).to eq("example.com/relative") }
    end

    context "when fetching host for address with custom port" do
      let(:host) { gitlab_address.host_with_port("http://example.com:3322/relative", with_default_port: false) }

      it { expect(host).to eq("example.com:3322/relative") }
    end
  end
end
