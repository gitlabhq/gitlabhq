# coding: utf-8
require 'spec_helper'

describe Gitlab::Regex do
  describe '.environment_scope_regex' do
    subject { described_class.environment_scope_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('foo*Z') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.feature_flag_regex' do
    subject { described_class.feature_flag_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('f_feature_flag') }
    it { is_expected.not_to match('MY_FEATURE_FLAG') }
    it { is_expected.not_to match('my feature flag') }
    it { is_expected.not_to match('!!()()') }
  end
end
