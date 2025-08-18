# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeedTokenHelper, feature_category: :system_access do
  let_it_be(:current_user) { build(:user, feed_token: 'KNOWN VALUE') }

  shared_examples 'returning a valid feed token' do
    context 'with type :atom' do
      it "returns the current_user's atom feed_token" do
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper).to receive(:current_request).and_return(instance_double(ActionDispatch::Request, path: 'url'))

        # The middle part is the output of OpenSSL::HMAC.hexdigest("SHA256", 'KNOWN VALUE', 'url.atom')
        expect(helper.generate_feed_token(:atom)).to eq(
          "#{expected_prefix}a8cc74ccb0de004d09a968705ba49099229b288b3de43f26c473a9d8d7fb7693-#{current_user.id}"
        )
      end
    end
  end

  context 'with default instance prefix' do
    let(:expected_prefix) { ::User::FEED_TOKEN_PREFIX }

    it_behaves_like 'returning a valid feed token'
  end

  context 'with custom instance prefix' do
    let_it_be(:instance_prefix) { 'instanceprefix' }
    let(:expected_prefix) { "#{instance_prefix}-glft-" }

    before do
      stub_application_setting(instance_token_prefix: instance_prefix)
    end

    it_behaves_like 'returning a valid feed token'

    context 'with feature flag custom_prefix_for_all_token_types disabled' do
      let(:expected_prefix) { ::User::FEED_TOKEN_PREFIX }

      before do
        stub_feature_flags(custom_prefix_for_all_token_types: false)
      end

      it_behaves_like 'returning a valid feed token'
    end
  end

  context 'when signed out' do
    it "returns nil" do
      allow(helper).to receive(:current_user).and_return(nil)

      expect(helper.generate_feed_token(:atom)).to be_nil
    end
  end
end
