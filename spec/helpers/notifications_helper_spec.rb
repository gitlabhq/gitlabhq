require 'spec_helper'

describe NotificationsHelper do
  describe 'notification_icon' do
    let(:notification) { double(disabled?: false, participating?: false, watch?: false) }

    context "disabled notification" do
      before { notification.stub(disabled?: true) }

      it "has a red icon" do
        notification_icon(notification).should match('class="icon-volume-off ns-mute"')
      end
    end

    context "participating notification" do
      before { notification.stub(participating?: true) }

      it "has a blue icon" do
        notification_icon(notification).should match('class="icon-volume-down ns-part"')
      end
    end

    context "watched notification" do
      before { notification.stub(watch?: true) }

      it "has a green icon" do
        notification_icon(notification).should match('class="icon-volume-up ns-watch"')
      end
    end

    it "has a blue icon" do
      notification_icon(notification).should match('class="icon-circle-blank ns-default"')
    end
  end
end
