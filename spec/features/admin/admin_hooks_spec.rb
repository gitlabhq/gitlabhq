require 'spec_helper'

describe "Admin::Hooks" do
  before do
    @project = create(:project)
    login_as :admin

    @system_hook = create(:system_hook)

  end

  describe "GET /admin/hooks" do
    it "should be ok" do
      visit admin_root_path
      within ".main_menu" do
        click_on "Hooks"
      end
      current_path.should == admin_hooks_path
    end

    it "should have hooks list" do
      visit admin_hooks_path
      page.should have_content(@system_hook.url)
    end
  end

  describe "New Hook" do
    before do
      @url = Faker::Internet.uri("http")
      visit admin_hooks_path
      fill_in "hook_url", with: @url
      expect { click_button "Add System Hook" }.to change(SystemHook, :count).by(1)
    end

    it "should open new hook popup" do
      page.current_path.should == admin_hooks_path
      page.should have_content(@url)
    end
  end

  describe "Test" do
    before do
      WebMock.stub_request(:post, @system_hook.url)
      visit admin_hooks_path
      click_link "Test Hook"
    end

    it { page.current_path.should == admin_hooks_path }
  end

end
