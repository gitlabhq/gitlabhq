# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EmojiHelper do
  describe '#emoji_icon' do
    let(:options) { {} }
    let(:emoji_text) { 'rocket' }
    let(:unicode_version) { '6.0' }
    let(:aria_hidden_option) { "aria-hidden=\"true\"" }

    subject { helper.emoji_icon(emoji_text, options) }

    it 'has no options' do
      is_expected.to include(
        '<gl-emoji',
        "title=\"#{emoji_text}\"",
        "data-name=\"#{emoji_text}\"",
        "data-unicode-version=\"#{unicode_version}\""
      )
      is_expected.not_to include(aria_hidden_option)
    end

    context 'with aria-hidden option' do
      let(:options) { { 'aria-hidden': true } }

      it 'applies aria-hidden' do
        is_expected.to include(
          '<gl-emoji',
          "title=\"#{emoji_text}\"",
          "data-name=\"#{emoji_text}\"",
          "data-unicode-version=\"#{unicode_version}\"",
          aria_hidden_option
        )
      end
    end
  end
end
