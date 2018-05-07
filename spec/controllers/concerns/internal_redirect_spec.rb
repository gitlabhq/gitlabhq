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
    it 'is `nil` for invalid uris' do
      expect(controller.safe_redirect_path('Hello world')).to be_nil
    end

    it 'is `nil` for paths trying to include a host' do
      expect(controller.safe_redirect_path('//example.com/hello/world')).to be_nil
    end

    it 'returns the path if it is valid' do
      expect(controller.safe_redirect_path('/hello/world')).to eq('/hello/world')
    end

    it 'returns the path with querystring if it is valid' do
      expect(controller.safe_redirect_path('/hello/world?hello=world#L123'))
        .to eq('/hello/world?hello=world#L123')
    end
  end

  describe '#safe_redirect_path_for_url' do
    it 'is `nil` for invalid urls' do
      expect(controller.safe_redirect_path_for_url('Hello world')).to be_nil
    end

    it 'is `nil` for urls from a with a different host' do
      expect(controller.safe_redirect_path_for_url('http://example.com/hello/world')).to be_nil
    end

    it 'is `nil` for urls from a with a different port' do
      expect(controller.safe_redirect_path_for_url('http://test.host:3000/hello/world')).to be_nil
    end

    it 'returns the path if the url is on the same host' do
      expect(controller.safe_redirect_path_for_url('http://test.host/hello/world')).to eq('/hello/world')
    end

    it 'returns the path including querystring if the url is on the same host' do
      expect(controller.safe_redirect_path_for_url('http://test.host/hello/world?hello=world#L123'))
        .to eq('/hello/world?hello=world#L123')
    end
  end

  describe '#host_allowed?' do
    it 'allows uris with the same host and port' do
      expect(controller.host_allowed?(URI('http://test.host/test'))).to be(true)
    end

    it 'rejects uris with other host and port' do
      expect(controller.host_allowed?(URI('http://example.com/test'))).to be(false)
    end
  end
end
