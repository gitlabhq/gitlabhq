require "spec_helper"

describe "User adds hook" do
  set(:group) { create(:group) }
  set(:user) { create(:user) }
  set(:url) { "http://example.org" }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  it "adds new hook" do
    fill_in("hook_url", with: url)

    expect { click_button("Add webhook") }.to change(GroupHook, :count).by(1)
    expect(current_path).to eq group_hooks_path(group)
    expect(page).to have_content(url)
  end
end
