# frozen_string_literal: true

require 'fast_spec_helper'
require 'haml_lint'
require 'haml_lint/spec'

require_relative '../../../haml_lint/linter/template_format'

RSpec.describe HamlLint::Linter::TemplateFormat, feature_category: :tooling do
  include_context 'linter'

  subject(:linter) { described_class.new(config) }

  let(:haml) { '%p Hello' }
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
      file: file
    }
  end

  context 'when the filename has no template format' do
    let(:file) { 'app/views/foo/show.haml' }

    it 'reports on line 1' do
      is_expected.to report_lint line: 1, message: start_with('Filename `show.haml` is missing a template format')
    end

    it 'suggests the .html.haml filename' do
      expect(linter.lints.first.message).to include('Rename it to `show.html.haml`')
    end
  end

  context 'when a partial filename has no template format' do
    let(:file) { 'app/views/foo/_bar.haml' }

    it { is_expected.to report_lint line: 1 }
  end

  context 'when the filename has a typo in the template format' do
    let(:file) { 'app/views/foo/show.hmtl.haml' }

    it 'reports and suggests replacing the bogus format' do
      expect(linter.lints.first.message).to include('Rename it to `show.html.haml`')
    end
  end

  context 'when the filename has the .html template format' do
    let(:file) { 'app/views/foo/show.html.haml' }

    it { is_expected.not_to report_lint }
  end

  %w[text js atom ics xml json csv].each do |format|
    context "when the filename has the .#{format} template format" do
      let(:file) { "app/views/foo/show.#{format}.haml" }

      it { is_expected.not_to report_lint }
    end
  end

  context 'when allowed_formats is configured' do
    let(:config) do
      HamlLint::ConfigurationLoader.default_configuration
        .merge(HamlLint::Configuration.new(
          'linters' => { 'TemplateFormat' => { 'allowed_formats' => %w[html] } }
        )).for_linter(described_class)
    end

    context 'with an allowed format' do
      let(:file) { 'app/views/foo/show.html.haml' }

      it { is_expected.not_to report_lint }
    end

    context 'with a format not in the list' do
      let(:file) { 'app/views/foo/show.text.haml' }

      it { is_expected.to report_lint line: 1 }
    end
  end
end
