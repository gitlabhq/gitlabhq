require 'spec_helper'

describe BroadcastMessagesHelper do
  describe 'broadcast_styling' do
    let(:broadcast_message) { double(color: "", font: "") }

    context "default style" do
      it "should have no style" do
        broadcast_styling(broadcast_message).should match('')
      end
    end

    context "customiezd style" do
      before { broadcast_message.stub(color: "#f2dede", font: "#b94a48") }

      it "should have a customized style" do
        broadcast_styling(broadcast_message).should match('background-color:#f2dede;color:#b94a48')
      end
    end
  end
end
