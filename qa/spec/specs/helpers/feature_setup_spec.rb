# frozen_string_literal: true

describe QA::Specs::Helpers::FeatureSetup do
  include QA::Support::Helpers::StubEnv

  let(:rspec_config) { instance_double(RSpec::Core::Configuration) }
  let(:options) { {} }
  let(:feature_enabled) { true }

  let(:feature_flags_env) { "" }
  let(:feature_flags) { feature_flags_env.split(",").to_h { |ff| ff.split("=") } }

  before do
    stub_env('QA_FEATURE_FLAGS', feature_flags_env)

    allow(RSpec).to receive(:configure).and_yield(rspec_config)
    allow(rspec_config).to receive(:before).with(:suite).and_yield
    allow(rspec_config).to receive(:after).with(:suite).and_yield

    allow(QA::Support::GlobalOptions).to receive(:get).and_return(options)
    allow(QA::Runtime::Feature).to receive(:disable)
    allow(QA::Runtime::Feature).to receive(:enable)
    allow(QA::Runtime::Feature).to receive(:set).with(feature_flags)
    allow(QA::Runtime::Feature).to receive(:enabled?).and_return(feature_enabled)
    allow(QA::Runtime::Logger).to receive(:logger).and_return(instance_double(ActiveSupport::Logger, error: nil))

    described_class.configure!
  end

  context "without any features configured" do
    it "doesn't perform any operations" do
      expect(QA::Runtime::Feature).not_to have_received(:set)
      expect(QA::Runtime::Feature).not_to have_received(:enable)
      expect(QA::Runtime::Feature).not_to have_received(:disable)
    end
  end

  context "with enabling a feature" do
    let(:options) { { enable_feature: 'a-feature' } }

    context "when feature is not enabled" do
      let(:feature_enabled) { false }

      it "enables and restores feature" do
        expect(QA::Runtime::Feature).to have_received(:enable).with(options[:enable_feature])
        expect(QA::Runtime::Feature).to have_received(:disable).with(options[:enable_feature])
      end
    end

    context "when feature is already enabled" do
      it "skips feature" do
        expect(QA::Runtime::Feature).not_to have_received(:disable)
        expect(QA::Runtime::Feature).not_to have_received(:enable)
      end
    end
  end

  context "with disabling a feature" do
    let(:options) { { disable_feature: 'a-feature' } }

    context "when feature is enabled" do
      it "disables and restore feature" do
        expect(QA::Runtime::Feature).to have_received(:disable).with(options[:disable_feature])
        expect(QA::Runtime::Feature).to have_received(:enable).with(options[:disable_feature])
      end
    end

    context "when feature is already disabled" do
      let(:feature_enabled) { false }

      it "skips feature" do
        expect(QA::Runtime::Feature).not_to have_received(:disable)
        expect(QA::Runtime::Feature).not_to have_received(:enable)
      end
    end
  end

  context "with feature flags" do
    context "with valid ff string" do
      let(:feature_flags_env) { "some_flag=enabled,some_other_flag=disabled" }

      it "sets feature flags" do
        expect(QA::Runtime::Feature).to have_received(:set).with(feature_flags)
      end
    end

    context "with not valid ff string" do
      let(:feature_flags_env) { "some_flag=enabled,some_other_flag=invalid_state" }
      let(:feature_flags) { { "some_flag" => "enabled" } }

      it "skips invalid pair" do
        expect(QA::Runtime::Feature).to have_received(:set).with(feature_flags)
      end
    end
  end
end
