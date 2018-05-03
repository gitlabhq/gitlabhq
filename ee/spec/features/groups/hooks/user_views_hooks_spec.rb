require "spec_helper"

describe "User views hooks" do
  set(:group) { create(:group) }
  set(:hook) { create(:group_hook, group: group) }
  set(:user) { create(:user) }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  it { expect(page).to have_content(hook.url) }
end
