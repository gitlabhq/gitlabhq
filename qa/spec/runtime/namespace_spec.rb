# frozen_string_literal: true

RSpec.describe QA::Runtime::Namespace do
  include QA::Support::Helpers::StubEnv

  let!(:time) { described_class.time }

  before(:context) do
    described_class.instance_variable_set(:@time, nil)
  end

  shared_examples "sandbox naming for live environments" do
    context "when the job does not use parallel" do
      it "returns a random sandbox name 1-8" do
        expect(described_class.sandbox_name).to match(%r{gitlab-e2e-sandbox-group-[1-8]})
      end
    end

    context "when the job uses parallel" do
      it "returns sandbox name based on CI_NODE_INDEX" do
        stub_env('CI_NODE_INDEX', '3')

        expect(described_class.sandbox_name).to match('gitlab-e2e-sandbox-group-3')
      end
    end
  end

  describe '.group_name' do
    it "returns unique name with predefined pattern" do
      expect(described_class.group_name).to match(/e2e-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}-[a-f0-9]{16}/)
    end
  end

  describe '.sandbox_name' do
    let(:dot_com) { false }
    let(:release) { false }

    before do
      described_class.instance_variable_set(:@live_env, nil)
      allow(QA::Runtime::Env).to receive_messages(
        running_on_dot_com?: dot_com,
        running_on_release?: release
      )
    end

    context "when running on .com environment" do
      let(:dot_com) { true }

      it_behaves_like "sandbox naming for live environments"
    end

    context "when running on release environment" do
      let(:release) { true }

      it_behaves_like "sandbox naming for live environments"
    end

    context "when running on ephemeral environment" do
      it "returns random sandbox name" do
        expect(described_class.sandbox_name).to match(/e2e-sandbox-[a-f0-9]{12}/)
      end
    end
  end
end
