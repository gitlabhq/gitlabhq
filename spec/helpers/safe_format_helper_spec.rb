# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeFormatHelper, feature_category: :shared do
  describe '#safe_format' do
    shared_examples 'safe formatting' do |format, args:, result:|
      subject { helper.safe_format(format, **args) }

      it { is_expected.to eq(result) }
      it { is_expected.to be_html_safe }
    end

    it_behaves_like 'safe formatting', '', args: {}, result: ''
    it_behaves_like 'safe formatting', 'Foo', args: {}, result: 'Foo'

    it_behaves_like 'safe formatting', '<b>strong</b>', args: {},
      result: '&lt;b&gt;strong&lt;/b&gt;'

    it_behaves_like 'safe formatting', '%{open}strong%{close}',
      args: { open: '<b>'.html_safe, close: '</b>'.html_safe },
      result: '<b>strong</b>'

    it_behaves_like 'safe formatting', '%{open}strong%{close} %{user_input}',
      args: { open: '<b>'.html_safe, close: '</b>'.html_safe,
              user_input: '<a href="">link</a>' },
      result: '<b>strong</b> &lt;a href=&quot;&quot;&gt;link&lt;/a&gt;'

    context 'when format is marked as html_safe' do
      it_behaves_like 'safe formatting', '<b>strong</b>'.html_safe, args: {},
        result: '&lt;b&gt;strong&lt;/b&gt;'
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
      it_behaves_like 'safe formatting', 'In &lt; hour',
        args: {},
        result: 'In &lt; hour'

      it_behaves_like 'safe formatting', '&quot;air&quot;',
        args: {},
        result: '&quot;air&quot;'

      it_behaves_like 'safe formatting', 'Mix & match &gt; all',
        args: {},
        result: 'Mix &amp; match &gt; all'
    end
  end
end
