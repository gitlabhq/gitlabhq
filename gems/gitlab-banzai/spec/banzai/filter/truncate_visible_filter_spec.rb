# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TruncateVisibleFilter do
  include FilterSpecHelper

  let(:max_chars) { 100 }

  def truncate(html, context = { truncate_visible_max_chars: max_chars })
    filter(html, context).to_html
  end

  it 'does not truncate without `truncate_visible_max_chars`' do
    html = "<p>#{'a' * 200}</p>"

    expect(truncate(html, {})).to eq(html)
  end

  it 'keeps markup that fits within the limit' do
    expect(truncate('<p>Text with <code>inline code</code></p>'))
      .to eq('<p>Text with <code>inline code</code></p>')
  end

  it 'truncates after the first block element' do
    expect(truncate('<p>Paragraph 1</p><p>Paragraph 2</p>')).to eq('<p>Paragraph 1...</p>')
  end

  it 'truncates a text node that crosses the limit' do
    text = 'The quick brown fox jumped over the lazy dog twice ' * 4

    expect(truncate("<p>#{text}</p>")).to eq("<p>#{text[0, 97]}...</p>")
  end

  it 'keeps the first line of a multi-line text node' do
    expect(truncate("<p>first\nsecond\nthird</p>")).to eq('<p>first...</p>')
  end

  it 'preserves a link href when the link text is truncated' do
    html = "<p>#{'x' * 95}<a href=\"http://example.com/foo/bar/baz\">http://example.com/foo/bar/baz</a></p>"

    result = truncate(html)

    expect(result).to include('href="http://example.com/foo/bar/baz"')
    expect(result).to include('>ht...</a>')
  end

  it 'does not truncate custom elements away from the visible text' do
    html = '<p>foo <gl-emoji data-name="wink">😉</gl-emoji> bar</p>'

    expect(truncate(html)).to eq(html)
  end
end
