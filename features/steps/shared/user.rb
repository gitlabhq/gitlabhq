module SharedUser
  include Spinach::DSL

  step 'User "John Doe" exists' do
    user_exists("John Doe", { username: "john_doe" })
  end

  step 'User "Mary Jane" exists' do
    user_exists("Mary Jane", { username: "mary_jane" })
  end

  step 'gitlab user "Mike"' do
    create(:user, name: "Mike")
  end

  protected

  def user_exists(name, options = {})
    User.find_by(name: name) || create(:user, { name: name, admin: false }.merge(options))
  end

  step 'I have no ssh keys' do
    @user.keys.delete_all
  end

  step 'I click on "Personal projects" tab' do
    page.within '.nav-links' do
      click_link 'Personal projects'
    end

    expect(page).to have_css('.tab-content #projects.active')
  end

  step 'I click on "Contributed projects" tab' do
    page.within '.nav-links' do
      click_link 'Contributed projects'
    end

    expect(page).to have_css('.tab-content #contributed.active')
  end
end
