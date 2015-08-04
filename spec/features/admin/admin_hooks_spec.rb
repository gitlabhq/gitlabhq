require 'spec_helper'

describe "Admin::Hooks", feature: true do
  before do
    @project = create(:project)
    login_as :admin

    @system_hook = create(:system_hook)

  end

  describe "GET /admin/hooks" do
    it "should be ok" do
      visit admin_root_path
      page.within ".sidebar-wrapper" do
        click_on "Hooks"
      end
      expect(current_path).to eq(admin_hooks_path)
    end

    it "should have hooks list" do
      visit admin_hooks_path
      expect(page).to have_content(@system_hook.url)
    end
  end

  describe "New Hook" do
    before do
      @url = FFaker::Internet.uri("http")
      visit admin_hooks_path
      fill_in "hook_url", with: @url
      expect { click_button "Add System Hook" }.to change(SystemHook, :count).by(1)
    end

    it "should open new hook popup" do
      expect(current_path).to eq(admin_hooks_path)
      expect(page).to have_content(@url)
    end
  end

  describe "Test" do
    before do
      WebMock.stub_request(:post, @system_hook.url)
      visit admin_hooks_path
      click_link "Test Hook"
    end

    it { expect(current_path).to eq(admin_hooks_path) }
  end

end
