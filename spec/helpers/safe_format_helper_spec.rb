# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeFormatHelper, feature_category: :shared do
  describe '#safe_format' do
    shared_examples 'safe formatting' do
      subject { helper.safe_format(format, args) }

      it { is_expected.to eq(result) }
      it { is_expected.to be_html_safe }
    end

    it_behaves_like 'safe formatting' do
      let(:format) { '' }
      let(:args) { {} }
      let(:result) { '' }
    end

    it_behaves_like 'safe formatting' do
      let(:format) { 'Foo' }
      let(:args) { {} }
      let(:result) { 'Foo' }
    end

    it_behaves_like 'safe formatting' do
      let(:format) { '<b>strong</b>' }
      let(:args) { {} }
      let(:result) { '&lt;b&gt;strong&lt;/b&gt;' }
    end

    it_behaves_like 'safe formatting' do
      let(:format) { '%{open}strong%{close}' }
      let(:args) { { open: '<b>'.html_safe, close: '</b>'.html_safe } }
      let(:result) { '<b>strong</b>' }
    end

    it_behaves_like 'safe formatting' do
      let(:format) { '%{open}strong%{close} %{user_input}' }

      let(:args) do
        { open: '<b>'.html_safe, close: '</b>'.html_safe,
          user_input: '<a href="">link</a>' }
      end

      let(:result) { '<b>strong</b> &lt;a href=&quot;&quot;&gt;link&lt;/a&gt;' }
    end

    context 'when format is marked as html_safe' do
      it_behaves_like 'safe formatting' do
        let(:format) { '<b>strong</b>'.html_safe }
        let(:args) { {} }
        let(:result) { '&lt;b&gt;strong&lt;/b&gt;' }
      end
    end

    context 'with multiple args' do
      it_behaves_like 'safe formatting' do
        let(:format) { '%{a}c%{b} %{x}z%{y}' }

        let(:args) do
          [
            { a: '<a>'.html_safe, b: '</a>'.html_safe },
            # Demonstrate shadowing
            { x: '<XX>'.html_safe, y: '</XX>'.html_safe },
            { x: '<x>'.html_safe, y: '</x>'.html_safe }
          ]
        end

        let(:result) { '<a>c</a> <x>z</x>' }

        subject { helper.safe_format(format, *args) }
      end
    end

    context 'with a view component' do
      let(:view_component) do
        Class.new(ViewComponent::Base) do
          include SafeFormatHelper

          def call
            safe_format('<b>%{value}</b>', value: '<br>')
          end
        end
      end

      it 'safetly formats' do
        expect(view_component.new.call)
          .to eq('&lt;b&gt;&lt;br&gt;&lt;/b&gt;')
      end
    end

    context 'with format containing escaped entities' do
      it_behaves_like 'safe formatting' do
        let(:format) { 'In &lt; hour' }
        let(:args) { {} }
        let(:result) { 'In &lt; hour' }
      end

      it_behaves_like 'safe formatting' do
        let(:format) { '&quot;air&quot;' }
        let(:args) { {} }
        let(:result) { '&quot;air&quot;' }
      end

      it_behaves_like 'safe formatting' do
        let(:format) { 'Mix & match &gt; all' }
        let(:args) { {} }
        let(:result) { 'Mix &amp; match &gt; all' }
      end
    end
  end

  describe '#tag_pair' do
    using RSpec::Parameterized::TableSyntax

    let(:tag) { plain_tag.html_safe }
    let(:open_name) { :tag_open }
    let(:close_name) { :tag_close }

    subject(:result) { tag_pair(tag, open_name, close_name) }

    where(:plain_tag, :open, :close) do
      ''                 | nil           | nil
      'a'                | nil           | nil
      '<a'               | nil           | nil
      '<a>'              | nil           | nil
      '<a><a>'           | nil           | nil
      '<input/>'         | nil           | nil
      '<a></a>'          | '<a>'         | '</a>'
      '<a href="">x</a>' | '<a href="">' | '</a>'
    end

    with_them do
      if params[:open] && params[:close]
        it { is_expected.to eq({ open_name => open, close_name => close }) }
        specify { expect(result.values).to be_all(&:html_safe?) }
      else
        it { is_expected.to eq({}) }
      end
    end

    context 'when tag is not html_safe' do
      # `to_str` turns a html_safe string into a plain String.
      let(:tag) { helper.tag.strong.to_str }

      it 'raises an ArgumentError' do
        expect { result }.to raise_error ArgumentError, 'Argument `tag` must be `html_safe`!'
      end
    end
  end
end
