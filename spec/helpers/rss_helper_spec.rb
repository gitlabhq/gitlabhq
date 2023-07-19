# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RssHelper do
  describe '#rss_url_options' do
    context 'when signed in' do
      it "includes the current_user's feed_token" do
        current_user = create(:user)
        allow(helper).to receive(:current_user).and_return(current_user)

        feed_token = helper.rss_url_options[:feed_token]
        expect(feed_token).to match(Gitlab::Auth::AuthFinders::PATH_DEPENDENT_FEED_TOKEN_REGEX)
        expect(feed_token).to end_with(current_user.id.to_s)
      end
    end

    context 'when signed out' do
      it "does not have a feed_token" do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.rss_url_options[:feed_token]).to be_nil
      end
    end

    context 'when feed_token disabled' do
      it "does not have a feed_token" do
        current_user = create(:user)
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(Gitlab::CurrentSettings).to receive(:disable_feed_token).and_return(true)
        expect(helper.rss_url_options[:feed_token]).to be_nil
      end
    end
  end
end
