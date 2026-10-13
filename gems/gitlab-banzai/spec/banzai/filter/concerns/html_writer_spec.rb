# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::Concerns::HtmlWriter do
  subject(:writer) do
    Class.new do
      include Banzai::Filter::Concerns::HtmlWriter
    end.new
  end

  it 'writes an opening tag with no attributes' do
    expect(writer.write_opening_tag('br', {})).to eq('<br>')
  end

  it 'escapes attribute values' do
    html = writer.write_opening_tag('a', { 'href' => 'https://example.com/?a=1&b=2', 'title' => '"<x>"' })

    expect(html).to eq('<a href="https://example.com/?a=1&amp;b=2" title="&quot;&lt;x&gt;&quot;">')
  end

  it 'skips nil attribute values' do
    expect(writer.write_opening_tag('a', { 'href' => '/x', 'rel' => nil })).to eq('<a href="/x">')
  end

  it 'round-trips the logical DOM value of every attribute' do
    attributes = { 'href' => 'https://example.com/?a=1&b=2', 'title' => '"quoted" & <tagged>' }

    element = Nokogiri::HTML.fragment(writer.write_opening_tag('a', attributes)).child

    expect(element.to_h).to match(attributes)
  end
end
