require 'spec_helper'

describe UserHelper do
  describe :user_avatar_url do
    let (:user) { User.new({'avatar_url' => avatar_url}) }

    context 'no avatar' do
      let (:avatar_url) { nil }

      it 'should return a generic avatar' do
        user_avatar_url(user).should == 'ci/no_avatar.png'
      end
    end

    context 'plain gravatar' do
      let (:base_url) { 'http://www.gravatar.com/avatar/abcdefgh' }
      let (:avatar_url) { "#{base_url}?s=40&d=mm" }

      it 'should return gravatar with default size' do
        user_avatar_url(user).should == "#{base_url}?s=40&d=identicon"
      end

      it 'should return gravatar with custom size' do
        user_avatar_url(user, 120).should == "#{base_url}?s=120&d=identicon"
      end
    end

    context 'secure gravatar' do
      let (:base_url) { 'https://secure.gravatar.com/avatar/abcdefgh' }
      let (:avatar_url) { "#{base_url}?s=40&d=mm" }

      it 'should return gravatar with default size' do
        user_avatar_url(user).should == "#{base_url}?s=40&d=identicon"
      end

      it 'should return gravatar with custom size' do
        user_avatar_url(user, 120).should == "#{base_url}?s=120&d=identicon"
      end
    end

    context 'custom avatar' do
      let (:avatar_url) { 'http://example.local/avatar.png' }

      it 'should return custom avatar' do
        user_avatar_url(user).should == avatar_url
      end
    end
  end
end
