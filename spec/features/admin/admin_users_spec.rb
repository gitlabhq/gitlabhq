require 'spec_helper'

describe "Admin::Users", feature: true  do
  before { login_as :admin }

  describe "GET /admin/users" do
    before do
      visit admin_users_path
    end

    it "should be ok" do
      expect(current_path).to eq(admin_users_path)
    end

    it "should have users list" do
      expect(page).to have_content(@user.email)
      expect(page).to have_content(@user.name)
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
      user = User.find_by(username: 'bang')
      expect(user.projects_limit).
        to eq(Gitlab.config.gitlab.default_projects_limit)
      expect(user.can_create_group).
        to eq(Gitlab.config.gitlab.default_can_create_group)
    end

    it "should create user with valid data" do
      click_button "Create user"
      user = User.find_by(username: 'bang')
      expect(user.name).to eq('Big Bang')
      expect(user.email).to eq('bigbang@mail.com')
    end

    it "should call send mail" do
      expect(Notify).to receive(:new_user_email)

      click_button "Create user"
    end

    it "should send valid email to user with email & password" do
      click_button "Create user"
      user = User.find_by(username: 'bang')
      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to have_content('Account was created')
      expect(email.text_part.body).to have_content(user.email)
      expect(email.text_part.body).to have_content('password')
    end
  end

  describe "GET /admin/users/:id" do
    before do
      visit admin_users_path
      click_link "#{@user.name}"
    end

    it "should have user info" do
      expect(page).to have_content(@user.email)
      expect(page).to have_content(@user.name)
    end
  end

  describe "GET /admin/users/:id/edit" do
    before do
      @simple_user = create(:user)
      visit admin_users_path
      click_link "edit_user_#{@simple_user.id}"
    end

    it "should have user edit page" do
      expect(page).to have_content('Name')
      expect(page).to have_content('Password')
    end

    describe "Update user" do
      before do
        fill_in "user_name", with: "Big Bang"
        fill_in "user_email", with: "bigbang@mail.com"
        check "user_admin"
        click_button "Save changes"
      end

      it "should show page with  new data" do
        expect(page).to have_content('bigbang@mail.com')
        expect(page).to have_content('Big Bang')
      end

      it "should change user entry" do
        @simple_user.reload
        expect(@simple_user.name).to eq('Big Bang')
        expect(@simple_user.is_admin?).to be_truthy
      end
    end
  end
end
