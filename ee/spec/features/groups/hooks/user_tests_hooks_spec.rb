require "spec_helper"

describe "User tests hooks" do
  set(:group) { create(:group) }
  set(:hook) { create(:group_hook, group: group) }
  set(:user) { create(:user) }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  context "when project is not empty" do
    let!(:project) { create(:project, :repository, group: group) }

    context "when URL is valid" do
      before do
        trigger_hook
      end

      it "triggers a hook" do
        expect(current_path).to eq(group_hooks_path(group))
        expect(page).to have_selector(".flash-notice", text: "Hook executed successfully: HTTP 200")
      end
    end

    context "when URL is invalid" do
      before do
        stub_request(:post, hook.url).to_raise(SocketError.new("Failed to open"))

        click_link("Test")
      end

      it { expect(page).to have_selector(".flash-alert", text: "Hook execution failed: Failed to open") }
    end
  end

  context "when project is empty" do
    let!(:project) { create(:project, group: group) }

    before do
      trigger_hook
    end

    it { expect(page).to have_selector('.flash-alert', text: 'Hook execution failed. Ensure the group has a project with commits.') }
  end

  private

  def trigger_hook
    stub_request(:post, hook.url).to_return(status: 200)

    click_link("Test")
  end
end
