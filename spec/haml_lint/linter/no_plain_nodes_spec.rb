# frozen_string_literal: true

require 'fast_spec_helper'
require 'haml_lint'
require 'haml_lint/spec'

require_relative '../../../haml_lint/linter/no_plain_nodes'

RSpec.describe HamlLint::Linter::NoPlainNodes, feature_category: :tooling do
  include_context 'linter'

  context 'reports when a tag has an inline plain node' do
    let(:haml) { '%tag Hello Tanuki' }
    let(:message) { "`Hello Tanuki` is a plain node. Please use an i18n method like `= _('Hello Tanuki')`" }

    it { is_expected.to report_lint message: message }
  end

  context 'reports when a tag has multiline plain nodes' do
    let(:haml) { <<-HAML }
      %tag
        Hello
        Tanuki
    HAML

    it { is_expected.to report_lint count: 1 }
  end

  context 'reports when a tag has an inline plain node with interpolation' do
    let(:haml) { '%tag Hello #{"Tanuki"}!' } # rubocop:disable Lint/InterpolationCheck

    it { is_expected.to report_lint }
  end

  context 'does not report when a tag has an inline script' do
    let(:haml) { '%tag= "Hello Tanuki"' }

    it { is_expected.not_to report_lint }
  end

  context 'does not report when a tag is empty' do
    let(:haml) { '%tag' }

    it { is_expected.not_to report_lint }
  end

  context 'reports multiple when a tag has multiline plain nodes split by non-text nodes' do
    let(:haml) { <<-HAML }
      %tag
        Hello
        .split-node There
        Tanuki
    HAML

    it { is_expected.to report_lint count: 3 }
  end

  context 'does not report when a html entity' do
    let(:haml) { '%tag &nbsp;' }

    it { is_expected.not_to report_lint }
  end

  context 'does report when something that looks like a html entity' do
    let(:haml) { '%tag &some text;' }

    it { is_expected.to report_lint }
  end

  context 'does not report multiline when one or more html entities' do
    %w[&nbsp;&gt; &#x000A9; &#187;].each do |elem|
      context "with #{elem}" do
        let(:haml) { <<-HAML }
          %tag
            #{elem}
        HAML

        it { is_expected.not_to report_lint }
      end
    end
  end

  context 'does report multiline when one or more html entities amidst plain text' do
    %w[&nbsp;Test Test&gt; &#x000A9;Hello &nbsp;Hello&#187;].each do |elem|
      context "with #{elem}" do
        let(:haml) { <<-HAML }
          %tag
            #{elem}
        HAML

        it { is_expected.to report_lint }
      end
    end
  end
end
