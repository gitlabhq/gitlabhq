# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabScriptTagHelper do
  before do
    allow(helper).to receive(:content_security_policy_nonce).and_return('noncevalue')
  end

  describe 'external script tag' do
    let(:script_url) { 'test.js' }

    it 'returns a script tag with defer=true and a nonce' do
      expect(helper.javascript_include_tag(script_url).to_s)
        .to eq "<script src=\"/javascripts/#{script_url}\" defer=\"defer\" nonce=\"noncevalue\"></script>"
    end

    it 'returns a script tag with defer=false and a nonce' do
      expect(helper.javascript_include_tag(script_url, defer: nil).to_s)
        .to eq "<script src=\"/javascripts/#{script_url}\" nonce=\"noncevalue\"></script>"
    end

    it 'returns a script tag with a nonce even nonce is set to nil' do
      expect(helper.javascript_include_tag(script_url, nonce: nil).to_s)
        .to eq "<script src=\"/javascripts/#{script_url}\" defer=\"defer\" nonce=\"noncevalue\"></script>"
    end
  end

  describe 'inline script tag' do
    let(:tag_with_nonce) { "<script nonce=\"noncevalue\">\n//<![CDATA[\nalert(1)\n//]]>\n</script>" }
    let(:tag_with_nonce_and_type) { "<script type=\"application/javascript\" nonce=\"noncevalue\">\n//<![CDATA[\nalert(1)\n//]]>\n</script>" }

    it 'returns a script tag with a nonce using block syntax' do
      expect(helper.javascript_tag { 'alert(1)' }.to_s).to eq tag_with_nonce
    end

    it 'returns a script tag with a nonce using block syntax with options' do
      expect(helper.javascript_tag(type: 'application/javascript') { 'alert(1)' }.to_s).to eq tag_with_nonce_and_type
    end

    it 'returns a script tag with a nonce using argument syntax' do
      expect(helper.javascript_tag('alert(1)').to_s).to eq tag_with_nonce
    end

    it 'returns a script tag with a nonce using argument syntax with options' do
      expect(helper.javascript_tag('alert(1)', type: 'application/javascript').to_s).to eq tag_with_nonce_and_type
    end

    # This scenario does not really make sense, but it's supported so we test it
    it 'returns a script tag with a nonce using argument and block syntax with options' do
      expect(helper.javascript_tag('// ignored', type: 'application/javascript') { 'alert(1)' }.to_s).to eq tag_with_nonce_and_type
    end
  end

  describe '#preload_link_tag' do
    it 'returns a link tag with a nonce' do
      expect(helper.preload_link_tag('https://example.com/script.js').to_s)
        .to eq "<link rel=\"preload\" href=\"https://example.com/script.js\" as=\"script\" type=\"text/javascript\" nonce=\"noncevalue\">"
    end
  end
end
