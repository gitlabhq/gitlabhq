# frozen_string_literal: true

require 'fast_spec_helper'
require 'haml_lint'
require 'haml_lint/spec'

require_relative '../../../haml_lint/linter/documentation_links'

RSpec.describe HamlLint::Linter::DocumentationLinks, feature_category: :tooling do
  include_context 'linter'

  shared_examples 'link validation rules' do |link_pattern|
    context 'when link_to points to the existing file path' do
      let(:haml) { "= link_to 'Description', #{link_pattern}('index.md')" }

      it { is_expected.not_to report_lint }
    end

    context 'when link_to points to the existing file with valid anchor' do
      let(:haml) { "= link_to 'Description', #{link_pattern}('index.md', anchor: 'user-accounts'), target: '_blank'" }

      it { is_expected.not_to report_lint }
    end

    context 'when link_to points to the existing file path without .md extension' do
      let(:haml) { "= link_to 'Description', #{link_pattern}('index')" }

      it { is_expected.to report_lint }
    end

    context 'when anchor is not correct' do
      let(:haml) { "= link_to 'Description', #{link_pattern}('index.md', anchor: 'wrong')" }

      it { is_expected.to report_lint }

      context "when #{link_pattern} has multiple options" do
        let(:haml) { "= link_to 'Description', #{link_pattern}('index.md', key: :value, anchor: 'wrong')" }

        it { is_expected.to report_lint }
      end
    end

    context 'when file path is wrong' do
      let(:haml) { "= link_to 'Description', #{link_pattern}('wrong.md'), target: '_blank'" }

      it { is_expected.to report_lint }

      context 'when haml ends with block definition' do
        let(:haml) { "= link_to 'Description', #{link_pattern}('wrong.md') do" }

        it { is_expected.to report_lint }
      end
    end

    context 'when link with wrong file path is assigned to a variable' do
      let(:haml) { "- my_link = link_to 'Description', #{link_pattern}('wrong.md')" }

      it { is_expected.to report_lint }
    end

    context 'when it is a broken code' do
      let(:haml) { "= I am broken! ]]]]" }

      it { is_expected.not_to report_lint }
    end

    context 'when anchor belongs to a different element' do
      let(:haml) { "= link_to 'Description', #{link_pattern}('index.md'), target: (anchor: 'blank')" }

      it { is_expected.not_to report_lint }
    end

    context "when a simple #{link_pattern}" do
      let(:haml) { "- url = #{link_pattern}('wrong')" }

      it { is_expected.to report_lint }
    end

    context 'when link is not a string' do
      let(:haml) { "- url = #{link_pattern}(help_url)" }

      it { is_expected.not_to report_lint }
    end

    context 'when link is a part of the tag' do
      let(:haml) { ".data-form{ data: { url: #{link_pattern}('wrong') } }" }

      it { is_expected.to report_lint }
    end

    context 'when the second link is invalid' do
      let(:haml) { ".data-form{ data: { url: #{link_pattern}('index.md'), wrong_url: #{link_pattern}('wrong') } }" }

      it { is_expected.to report_lint }
    end
  end

  it_behaves_like 'link validation rules', 'help_page_path'
  it_behaves_like 'link validation rules', 'help_page_url'
  it_behaves_like 'link validation rules', 'Rails.application.routes.url_helpers.help_page_url'
  it_behaves_like 'link validation rules', 'Gitlab::Routing.url_helpers.help_page_url'
end
