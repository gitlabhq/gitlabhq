require 'spec_helper'

describe "Admin::Users" do
  before { login_as :admin }

  describe "GET /admin/users" do
    before do
      visit admin_users_path
    end

    it "should be ok" do
      current_path.should == admin_users_path
    end

    it "should have users list" do
      page.should have_content(@user.email)
      page.should have_content(@user.name)
    end
  end

  describe "GET /admin/users/new" do
    before do
      visit new_admin_user_path
      fill_in "user_name", with: "Big Bang"
      fill_in "user_username", with: "bang"
      fill_in "user_email", with: "bigbang@mail.com"
    end

    it "should create new user" do
      expect { click_button "Create user" }.to change {User.count}.by(1)
    end

    it "should apply defaults to user" do
      click_button "Create user"
      user = User.last
      user.projects_limit.should == Gitlab.config.gitlab.default_projects_limit
      user.can_create_group.should == Gitlab.config.gitlab.default_can_create_group
      user.can_create_team.should == Gitlab.config.gitlab.default_can_create_team
    end

    it "should create user with valid data" do
      click_button "Create user"
      user = User.last
      user.name.should ==  "Big Bang"
      user.email.should == "bigbang@mail.com"
    end

    it "should call send mail" do
      Notify.should_receive(:new_user_email)

      User.observers.enable :user_observer do
        click_button "Create user"
      end
    end

    it "should send valid email to user with email & password" do
      User.observers.enable :user_observer do
        click_button "Create user"
        user = User.last
        email = ActionMailer::Base.deliveries.last
        email.subject.should have_content("Account was created")
        email.text_part.body.should have_content(user.email)
        email.text_part.body.should have_content('password')
      end
    end
  end

  describe "GET /admin/users/:id" do
    before do
      visit admin_users_path
      click_link "#{@user.name}"
    end

    it "should have user info" do
      page.should have_content(@user.email)
      page.should have_content(@user.name)
    end
  end

  describe "GET /admin/users/:id/edit" do
    before do
      @simple_user = create(:user)
      visit admin_users_path
      click_link "edit_user_#{@simple_user.id}"
    end

    it "should have user edit page" do
      page.should have_content("Name")
      page.should have_content("Password")
    end

    describe "Update user" do
      before do
        fill_in "user_name", with: "Big Bang"
        fill_in "user_email", with: "bigbang@mail.com"
        check "user_admin"
        click_button "Save changes"
      end

      it "should show page with  new data" do
        page.should have_content("bigbang@mail.com")
        page.should have_content("Big Bang")
      end

      it "should change user entry" do
        @simple_user.reload
        @simple_user.name.should == "Big Bang"
        @simple_user.is_admin?.should be_true
      end
    end
  end

  describe "Add new project" do
    before do
      @new_project = create(:project)
      visit admin_user_path(@user)
    end

    it "should create new user" do
      select @new_project.name, from: "project_ids"
      expect { click_button "Add" }.to change { UsersProject.count }.by(1)
      page.should have_content @new_project.name
      current_path.should == admin_user_path(@user)
    end
  end
end
