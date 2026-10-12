# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::Concerns::TextReplacer do
  subject(:replacer) do
    Class.new do
      include Banzai::Filter::Concerns::TextReplacer
    end.new
  end

  def replace(text, pattern, &block)
    replacer.replace_references_in_text_with_html(text.gsub(pattern), &block)
  end

  it 'substitutes the yielded HTML and escapes the surrounding text' do
    html = replace('a <b> #1 c', /#(\d+)/) { |match| "<a href=\"/i/#{match[1]}\">##{match[1]}</a>" }

    expect(html).to eq('a &lt;b&gt; <a href="/i/1">#1</a> c')
  end

  it 'returns nil when the enumerator yields nothing' do
    expect(replace('nothing here', /#(\d+)/) { 'unused' }).to be_nil
  end

  it 'returns nil when the block declines every match' do
    expect(replace('#1 and #2', /#(\d+)/) { nil }).to be_nil
  end

  it 'leaves declined matches as escaped text' do
    html = replace('#1 <and> #2', /#(\d+)/) { |match| match[1] == '1' ? '<b>one</b>' : nil }

    expect(html).to eq('<b>one</b> &lt;and&gt; #2')
  end

  it 'raises when the enumerator yields something other than match data' do
    expect { replacer.replace_references_in_text_with_html(%w[not match data].each) { 'x' } }
      .to raise_error(ArgumentError, /didn't yield MatchData/)
  end
end
