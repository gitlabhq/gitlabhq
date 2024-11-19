# frozen_string_literal: true

RSpec.describe QA::Runtime::Namespace do
  include QA::Support::Helpers::StubEnv

  let!(:time) { described_class.time }

  before(:context) do
    described_class.instance_variable_set(:@time, nil)
  end

  describe '.group_name' do
    it "returns unique name with predefined pattern" do
      expect(described_class.group_name).to match(/qa-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}-[a-f0-9]{16}/)
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

      it "returns day specific sandbox name" do
        expect(described_class.sandbox_name).to match(%r{gitlab-qa-sandbox-group-#{time.wday + 1}})
      end
    end

    context "when running on release environment" do
      let(:release) { true }

      it "returns day specific sandbox name" do
        expect(described_class.sandbox_name).to match(%r{gitlab-qa-sandbox-group-#{time.wday + 1}})
      end
    end

    context "when running on ephemeral environment" do
      it "returns random sandbox name" do
        expect(described_class.sandbox_name).to match(/qa-sandbox-[a-f0-9]{12}/)
      end
    end
  end
end
