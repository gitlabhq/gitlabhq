# frozen_string_literal: true

RSpec.describe QA::Runtime::Namespace do
  include QA::Support::Helpers::StubEnv

  let!(:time) { described_class.time }

  before(:context) do
    described_class.instance_variable_set(:@time, nil)
    described_class.instance_variable_set(:@sandbox_name, nil)
  end

  describe '.group_name' do
    it "returns unique name with predefined pattern" do
      expect(described_class.group_name).to match(/qa-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}-[a-f0-9]{16}/)
    end
  end

  describe '.sandbox_name' do
    before do
      allow(QA::Runtime::Scenario).to receive(:gitlab_address).and_return("http://gitlab.test")
    end

    it "returns day specific sandbox name" do
      expect(described_class.sandbox_name).to match(%r{gitlab-qa-sandbox-group-#{time.wday + 1}})
    end
  end
end
