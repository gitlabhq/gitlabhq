# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::SetDirectionFilter do
  include FilterSpecHelper

  it 'sets dir="auto" on top level block elements' do
    doc = filter('<p>foo</p><h1>bar</h1><ul><li>baz</li></ul><blockquote>qux</blockquote><table></table>')

    expect(doc.css('[dir="auto"]').map(&:name)).to eq(%w[p h1 ul blockquote table])
  end

  it 'leaves nested elements alone' do
    doc = filter('<blockquote><p>foo</p></blockquote>')

    expect(doc.at_css('blockquote p')['dir']).to be_nil
  end

  it 'skips the section navigation list' do
    doc = filter('<ul class="section-nav"><li>foo</li></ul>')

    expect(doc.at_css('ul')['dir']).to be_nil
  end

  it_behaves_like 'pipeline timing check'
end
