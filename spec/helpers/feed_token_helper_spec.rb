# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeedTokenHelper, feature_category: :system_access do
  describe '#generate_feed_token' do
    context 'with type :atom' do
      let(:current_user) { build(:user, feed_token: 'KNOWN VALUE') }

      it "returns the current_user's atom feed_token" do
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper).to receive(:current_request).and_return(instance_double(ActionDispatch::Request, path: 'url'))

        expect(helper.generate_feed_token(:atom))
          # The middle part is the output of OpenSSL::HMAC.hexdigest("SHA256", 'KNOWN VALUE', 'url.atom')
          .to eq("glft-a8cc74ccb0de004d09a968705ba49099229b288b3de43f26c473a9d8d7fb7693-#{current_user.id}")
      end
    end

    context 'when signed out' do
      it "returns nil" do
        allow(helper).to receive(:current_user).and_return(nil)

        expect(helper.generate_feed_token(:atom)).to be_nil
      end
    end
  end
end
