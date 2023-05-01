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
      let(:format) { '<b>strong</b>'.html_safe }
      let(:args) { {} }

      it 'raises an error' do
        message = 'Argument `format` must not be marked as html_safe!'

        expect { helper.safe_format(format, **args) }
          .to raise_error ArgumentError, message
      end
    end
  end
end
