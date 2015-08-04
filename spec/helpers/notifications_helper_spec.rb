require 'spec_helper'

describe NotificationsHelper do
  describe 'notification_icon' do
    let(:notification) { double(disabled?: false, participating?: false, watch?: false) }

    context "disabled notification" do
      before { allow(notification).to receive(:disabled?).and_return(true) }

      it "has a red icon" do
        expect(notification_icon(notification)).to match('class="fa fa-volume-off ns-mute"')
      end
    end

    context "participating notification" do
      before { allow(notification).to receive(:participating?).and_return(true) }

      it "has a blue icon" do
        expect(notification_icon(notification)).to match('class="fa fa-volume-down ns-part"')
      end
    end

    context "watched notification" do
      before { allow(notification).to receive(:watch?).and_return(true) }

      it "has a green icon" do
        expect(notification_icon(notification)).to match('class="fa fa-volume-up ns-watch"')
      end
    end

    it "has a blue icon" do
      expect(notification_icon(notification)).to match('class="fa fa-circle-o ns-default"')
    end
  end
end
