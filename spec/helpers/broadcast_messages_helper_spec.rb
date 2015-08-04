require 'spec_helper'

describe BroadcastMessagesHelper do
  describe 'broadcast_styling' do
    let(:broadcast_message) { double(color: '', font: '') }

    context "default style" do
      it "should have no style" do
        expect(broadcast_styling(broadcast_message)).to eq ''
      end
    end

    context "customized style" do
      let(:broadcast_message) { double(color: "#f2dede", font: '#b94a48') }

      it "should have a customized style" do
        expect(broadcast_styling(broadcast_message)).
          to match('background-color: #f2dede; color: #b94a48')
      end
    end
  end
end
