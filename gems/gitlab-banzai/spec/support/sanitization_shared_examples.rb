# frozen_string_literal: true

# Copies of the two link-sanitization shared examples in the monolith's
# `spec/support/shared_examples/lib/banzai/filters/sanitization_filter_shared_examples.rb`,
# which the monolith's sanitization filter specs still use.

RSpec.shared_examples 'XSS prevention' do
  # Adapted from the Sanitize test suite: http://git.io/vczrM
  protocols = {
    'protocol-based JS injection: simple, no spaces' => {
      input: '<a href="javascript:alert(\'XSS\');">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: simple, spaces before' => {
      input: '<a href="javascript    :alert(\'XSS\');">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: simple, spaces after' => {
      input: '<a href="javascript:    alert(\'XSS\');">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: simple, spaces before and after' => {
      input: '<a href="javascript    :   alert(\'XSS\');">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: preceding colon' => {
      input: '<a href=":javascript:alert(\'XSS\');">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: UTF-8 encoding' => {
      input: '<a href="javascript&#58;">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: long UTF-8 encoding' => {
      input: '<a href="javascript&#0058;">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: long UTF-8 encoding without semicolons' => {
      input: '<a href=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: hex encoding' => {
      input: '<a href="javascript&#x3A;">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: long hex encoding' => {
      input: '<a href="javascript&#x003A;">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: hex encoding without semicolons' => {
      input: '<a href=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>foo</a>',
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: null char' => {
      input: "<a href=java\0script:alert(\"XSS\")>foo</a>",
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: invalid URL char' => {
      input: '<img src=java\script:alert("XSS")>',
      output: '<img>'
    },

    'protocol-based JS injection: Unicode' => {
      input: %(<a href="\u0001java\u0003script:alert('XSS')">foo</a>),
      output: '<a>foo</a>'
    },

    'protocol-based JS injection: spaces and entities' => {
      input: '<a href=" &#14;  javascript:alert(\'XSS\');">foo</a>',
      output: '<a>foo</a>'
    },

    'protocol whitespace' => {
      input: '<a href=" http://example.com/"></a>',
      output: '<a href="http://example.com/"></a>'
    }
  }

  protocols.each do |name, data|
    it "disallows #{name}" do
      doc = filter(data[:input])

      expect(doc.to_html).to eq data[:output]
    end
  end

  it 'sanitizes javascript in attributes' do
    act = %q(<a href="javascript:alert('foo')">Text</a>)
    exp = '<a>Text</a>'
    expect(filter(act).to_html).to eq exp
  end

  it 'sanitizes mixed-cased javascript in attributes' do
    act = %q(<a href="javaScript:alert('foo')">Text</a>)
    exp = '<a>Text</a>'
    expect(filter(act).to_html).to eq exp
  end

  it 'disallows data links' do
    input = '<a href="data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K">XSS</a>'
    output = filter(input)

    expect(output.to_html).to eq '<a>XSS</a>'
  end

  it 'disallows vbscript links' do
    input = '<a href="vbscript:alert(document.domain)">XSS</a>'
    output = filter(input)

    expect(output.to_html).to eq '<a>XSS</a>'
  end
end

RSpec.shared_examples 'sanitize link' do
  it 'disallows invalid URIs' do
    expect(Addressable::URI).to receive(:parse).with('foo://example.com')
      .and_raise(Addressable::URI::InvalidURIError)

    input = '<a href="foo://example.com">Foo</a>'
    output = filter(input)

    expect(output.to_html).to eq '<a>Foo</a>'
  end

  it 'allows non-standard anchor schemes' do
    exp = %q(<a href="irc://irc.freenode.net/git">IRC</a>)
    act = filter(exp)

    expect(act.to_html).to eq exp
  end

  it 'allows relative links' do
    exp = %q(<a href="foo/bar.md">foo/bar.md</a>)
    act = filter(exp)

    expect(act.to_html).to eq exp
  end

  it 'limits to MAX_LINK_ATTRIBUTES links' do
    exp = %q(<a href="foo/bar.md">foo/bar.md</a>) * (Banzai::Filter::SanitizeLinkFilter::MAX_LINK_ATTRIBUTES + 1)
    act = filter(exp)

    expect(act.to_html).to eq Banzai::Filter::SanitizeLinkFilter::TIMEOUT_MARKDOWN_MESSAGE
  end
end
