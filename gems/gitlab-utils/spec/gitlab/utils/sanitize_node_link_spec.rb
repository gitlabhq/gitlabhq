# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'
require 'addressable'

RSpec.describe Gitlab::Utils::SanitizeNodeLink do
  let(:klass) do
    struct = Struct.new(:value)
    struct.include(described_class)

    struct
  end

  subject(:object) { klass.new(:value) }

  describe "#safe_protocol?" do
    invalid_schemes = [
      "javascript:",
      "JaVaScRiPt:",
      "\u0001java\u0003script:",
      "javascript    :",
      "javascript:    ",
      "javascript    :   ",
      ":javascript:",
      "javascript&#58;",
      "javascript&#0058;",
      " &#14;  javascript:"
    ]

    invalid_schemes.each do |scheme|
      context "with the scheme: #{scheme}" do
        it "returns false" do
          expect(object.safe_protocol?(scheme)).to be_falsy
        end
      end
    end

    it 'returns true for http' do
      expect(object.safe_protocol?('http')).to be_truthy
    end

    it 'returns true for https' do
      expect(object.safe_protocol?('https')).to be_truthy
    end

    it 'returns false for nil' do
      expect(object.safe_protocol?(nil)).to be_falsy
    end
  end

  describe '#permit_url?' do
    it 'permits safe URLs' do
      expect(object.permit_url?('http://example.com')).to be true
    end

    it 'permits URLs without a scheme' do
      expect(object.permit_url?('/relative/path')).to be true
    end

    it 'rejects javascript URLs' do
      expect(object.permit_url?('javascript:alert(1)')).to be false
    end

    it 'rejects data URLs' do
      expect(object.permit_url?('data:text/html,<script>alert(1)</script>')).to be false
    end

    context 'with invalid URIs' do
      it 'rejects them when remove_invalid_links is true' do
        expect(object.permit_url?('http://example:wrong_port.com', remove_invalid_links: true)).to be false
      end

      it 'permits them when remove_invalid_links is false' do
        expect(object.permit_url?('http://example:wrong_port.com', remove_invalid_links: false)).to be true
      end
    end

    context 'with a URL containing invalid UTF-8 bytes in the host' do
      let(:invalid_url) { (+"http://ex\xC3ample.com/").force_encoding('UTF-8') }

      it 'rejects the URL when remove_invalid_links is true' do
        expect(object.permit_url?(invalid_url, remove_invalid_links: true)).to be false
      end

      it 'permits the URL when remove_invalid_links is false' do
        expect(object.permit_url?(invalid_url, remove_invalid_links: false)).to be true
      end
    end

    context 'when normalize raises ArgumentError for invalid UTF-8 bytes' do
      let(:parsed) { instance_double(Addressable::URI) }

      before do
        allow(Addressable::URI).to receive(:parse).and_return(parsed)
        allow(parsed).to receive(:normalize).and_raise(ArgumentError, 'invalid byte sequence in UTF-8')
      end

      it 'rejects the URL when remove_invalid_links is true' do
        expect(object.permit_url?('http://example.com', remove_invalid_links: true)).to be false
      end

      it 'permits the URL when remove_invalid_links is false' do
        expect(object.permit_url?('http://example.com', remove_invalid_links: false)).to be true
      end
    end

    context 'when normalize raises an unrelated ArgumentError' do
      let(:parsed) { instance_double(Addressable::URI) }

      before do
        allow(Addressable::URI).to receive(:parse).and_return(parsed)
        allow(parsed).to receive(:normalize).and_raise(ArgumentError, 'something unrelated')
      end

      it 're-raises the error rather than silently masking it' do
        expect { object.permit_url?('http://example.com') }
          .to raise_error(ArgumentError, 'something unrelated')
      end
    end

    context 'when normalize raises Encoding::CompatibilityError' do
      let(:parsed) { instance_double(Addressable::URI) }

      before do
        allow(Addressable::URI).to receive(:parse).and_return(parsed)
        allow(parsed).to receive(:normalize).and_raise(Encoding::CompatibilityError)
      end

      it 'rejects the URL when remove_invalid_links is true' do
        expect(object.permit_url?('http://example.com', remove_invalid_links: true)).to be false
      end

      it 'permits the URL when remove_invalid_links is false' do
        expect(object.permit_url?('http://example.com', remove_invalid_links: false)).to be true
      end
    end
  end

  describe '#remove_unsafe_links' do
    it 'removes unsafe href attributes from nodes' do
      doc = Nokogiri::HTML.fragment('<a href="javascript:alert(1)">foo</a>')
      node = doc.children.first
      env = { node: node }

      object.remove_unsafe_links(env, sanitize_children: false)

      expect(node['href']).to be_nil
    end

    it 'keeps safe href attributes' do
      doc = Nokogiri::HTML.fragment('<a href="http://example.com">foo</a>')
      node = doc.children.first
      env = { node: node }

      object.remove_unsafe_links(env, sanitize_children: false)

      expect(node['href']).to eq('http://example.com')
    end

    it 'sanitizes child nodes when sanitize_children is true' do
      html = '<div><a href="javascript:alert(1)">bad</a><a href="http://ok.com">good</a></div>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.children.first
      env = { node: node }

      object.remove_unsafe_links(env, sanitize_children: true)

      expect(doc.at_css('a:first-child')['href']).to be_nil
      expect(doc.at_css('a:last-child')['href']).to eq('http://ok.com')
    end

    it 'does not sanitize child nodes when sanitize_children is false' do
      html = '<div><a href="javascript:alert(1)">bad</a></div>'
      doc = Nokogiri::HTML.fragment(html)
      node = doc.children.first
      env = { node: node }

      object.remove_unsafe_links(env, sanitize_children: false)

      expect(doc.at_css('a')['href']).to eq('javascript:alert(1)')
    end
  end
end
