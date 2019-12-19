# frozen_string_literal: true

require 'spec_helper'

describe InternalRedirect do
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
        'Hello world',
        '//example.com/hello/world',
        'https://example.com/hello/world',
        "not-starting-with-a-slash\n/starting/with/slash"
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
        '/-/ide/project/path'
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
        'Hello world',
        'http://example.com/hello/world',
        'http://test.host:3000/hello/world'
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
  end

  describe '#sanitize_redirect' do
    let(:valid_path) { '/hello/world?hello=world' }
    let(:valid_url) { "http://test.host#{valid_path}" }

    it 'returns `nil` for invalid paths' do
      invalid_path = '//not/valid'

      expect(controller.sanitize_redirect(invalid_path)).to eq nil
    end

    it 'returns `nil` for invalid urls' do
      input = 'http://test.host:3000/invalid'

      expect(controller.sanitize_redirect(input)).to eq nil
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
