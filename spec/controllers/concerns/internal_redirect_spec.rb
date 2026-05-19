# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InternalRedirect do
  let(:controller_class) do
    Class.new do
      include InternalRedirect

      def request
        @request ||= Struct.new(:host, :port).new('test.host', 80)
      end
    end
  end

  subject(:controller) { controller_class.new }

  describe '#safe_redirect_path' do
    where(:input) do
      [
        # Non-path inputs
        'Hello world',
        '/',
        'https://example.com/hello/world',
        "not-starting-with-a-slash\n/starting/with/slash",
        # Open redirect attack vectors (protocol-relative, backslash, dot prefix)
        '//example.com/hello/world',
        '//evil.com',
        '//evil.com/path',
        '/\\evil.com',
        '/.evil.com',
        "//evil.com\n/?legit=true",
        # Encoded open redirect variants
        '/%2Fevil.com',
        '/%2f%2fevil.com',
        '/%2f%2Fevil.com',
        '/%2F%2f%2fevil.com',
        # CRLF and control character injection
        "/hello\r\nX-Injected: header",
        "//evil.com\r\nLocation:https://evil.com",
        "//evil.com\rpath",
        "//evil.com\t/with-tab"
      ]
    end

    with_them 'being invalid' do
      it 'returns nil' do
        expect(controller.safe_redirect_path(input)).to be_nil
      end
    end

    where(:input) do
      [
        '/hello/world',
        '/-/ide/project/path',
        '/?non_archived=true&sort=name_asc'
      ]
    end

    with_them 'being valid' do
      it 'returns the path' do
        expect(controller.safe_redirect_path(input)).to eq(input)
      end

      it 'returns the path with querystring and fragment' do
        expect(controller.safe_redirect_path("#{input}?hello=world#L123"))
          .to eq("#{input}?hello=world#L123")
      end
    end
  end

  describe '#safe_redirect_path_for_url' do
    where(:input) do
      [
        # Non-URL or wrong host
        'Hello world',
        'http://example.com/hello/world',
        # Same host but different scheme or port
        'https://test.host/hello/world',
        'http://test.host:3000/hello/world',
        # Malformed or ambiguous URLs
        'http:///test.host/evil',
        'http://test.host@evil.com/x'
      ]
    end

    with_them 'being invalid' do
      it 'returns nil' do
        expect(controller.safe_redirect_path_for_url(input)).to be_nil
      end
    end

    where(:input) do
      [
        'http://test.host/hello/world'
      ]
    end

    with_them 'being on the same host' do
      let(:path) { URI(input).path }

      it 'returns the path' do
        expect(controller.safe_redirect_path_for_url(input)).to eq(path)
      end

      it 'returns the path with querystring and fragment' do
        expect(controller.safe_redirect_path_for_url("#{input}?hello=world#L123"))
          .to eq("#{path}?hello=world#L123")
      end
    end

    it 'accepts URL with empty userinfo when host matches' do
      # http://@test.host/hello has empty userinfo but host is test.host,
      # which passes host_allowed? - this is harmless
      expect(controller.safe_redirect_path_for_url('http://@test.host/hello')).to eq('/hello')
    end
  end

  describe '#sanitize_redirect' do
    let(:valid_path) { '/hello/world?hello=world' }
    let(:valid_url) { "http://test.host#{valid_path}" }

    where(:input) do
      [
        # Invalid paths
        '//not/valid',
        # Invalid URLs (wrong port)
        'http://test.host:3000/invalid',
        # CRLF injection
        "/hello\r\nworld",
        "http://test.host/hello\r\nworld",
        # Protocol-relative or wrong host
        '//evil.com',
        'http://evil.com/hello/world'
      ]
    end

    with_them 'being invalid' do
      it 'returns nil' do
        expect(controller.sanitize_redirect(input)).to be_nil
      end
    end

    it 'returns input for valid paths' do
      expect(controller.sanitize_redirect(valid_path)).to eq valid_path
    end

    it 'returns path for valid urls' do
      expect(controller.sanitize_redirect(valid_url)).to eq valid_path
    end
  end

  describe '#host_allowed?' do
    it 'allows URI with the same host and port' do
      expect(controller.host_allowed?(URI('http://test.host/test'))).to be(true)
    end

    it 'rejects URI with other host' do
      expect(controller.host_allowed?(URI('http://example.com/test'))).to be(false)
    end

    it 'rejects URI with other port' do
      expect(controller.host_allowed?(URI('http://test.host:3000/test'))).to be(false)
    end
  end
end
