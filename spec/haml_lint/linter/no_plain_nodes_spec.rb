# frozen_string_literal: true

require 'spec_helper'
require 'haml_lint'
require 'haml_lint/spec'
require Rails.root.join('haml_lint/linter/no_plain_nodes')

describe HamlLint::Linter::NoPlainNodes do
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
end
