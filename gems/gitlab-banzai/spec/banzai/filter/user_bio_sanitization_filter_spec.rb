# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::UserBioSanitizationFilter do
  include FilterSpecHelper

  it 'keeps `em`, `strong` and `code` elements' do
    html = '<em>one</em> <strong>two</strong> <code>three</code>'

    expect(filter(html).to_html).to eq(html)
  end

  it 'removes every other element and keeps its text' do
    expect(filter('<a href="https://example.com">link</a> <span>text</span>').to_html).to eq('link text')
  end

  it 'removes every attribute' do
    expect(filter('<em class="x" title="y">one</em>').to_html).to eq('<em>one</em>')
  end
end
