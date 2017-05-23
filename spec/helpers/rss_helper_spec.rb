require 'spec_helper'

describe RssHelper do
  describe '#rss_url_options' do
    context 'when signed in' do
      it "includes the current_user's rss_token" do
        current_user = create(:user)
        allow(helper).to receive(:current_user).and_return(current_user)
        expect(helper.rss_url_options).to include rss_token: current_user.rss_token
      end
    end

    context 'when signed out' do
      it "does not have an rss_token" do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.rss_url_options[:rss_token]).to be_nil
      end
    end
  end
end
