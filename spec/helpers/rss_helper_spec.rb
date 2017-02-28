require 'spec_helper'

describe RssHelper do
  describe '#rss_url_options' do
    context 'when signed in' do
      it "includes the current_user's private_token" do
        current_user = create(:user)
        allow(helper).to receive(:current_user).and_return(current_user)
        expect(helper.rss_url_options).to include private_token: current_user.private_token
      end
    end

    context 'when signed out' do
      it "does not have a private_token" do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.rss_url_options[:private_token]).to be_nil
      end
    end
  end
end
