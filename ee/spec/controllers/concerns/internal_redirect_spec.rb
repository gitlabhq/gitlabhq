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

  describe '#host_allowed?' do
    it 'allows redirecting to existing geo nodes' do
      create(:geo_node, url: 'http://narnia.test.host')

      expect(controller.host_allowed?(URI('http://narnia.test.host/test'))).to be(true)
    end
  end
end
