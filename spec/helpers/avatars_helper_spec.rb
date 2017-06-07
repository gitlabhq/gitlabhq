require 'rails_helper'

describe AvatarsHelper do
  let(:user) { create(:user) }

  describe '#user_avatar' do
    subject { helper.user_avatar(user: user) }

    it "links to the user's profile" do
      is_expected.to include("href=\"#{user_path(user)}\"")
    end

    it "has the user's name as title" do
      is_expected.to include("title=\"#{user.name}\"")
    end

    it "contains the user's avatar image" do
      is_expected.to include(CGI.escapeHTML(user.avatar_url(size: 16)))
    end
  end
end
