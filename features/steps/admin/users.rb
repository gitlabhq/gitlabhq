class Spinach::Features::AdminUsers < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I should see all users' do
    User.all.each do |user|
      page.should have_content user.name
    end
  end

  step 'Click edit' do
    @user = User.first
    find("#edit_user_#{@user.id}").click
  end

  step 'Input non ascii char in username' do
    fill_in 'user_username', with: "\u3042\u3044"
  end

  step 'Click save' do
    click_button("Save")
  end

  step 'See username error message' do
    within "#error_explanation" do
      page.should have_content "Username"
    end
  end

  step 'Not changed form action url' do
    page.should have_selector %(form[action="/admin/users/#{@user.username}"])
  end

  step 'I submit modified user' do
    check :user_can_create_group
    click_button 'Save'
  end

  step 'I see user attributes changed' do
    page.should have_content 'Can create groups: Yes'
  end

  step 'click edit on my user' do
    find("#edit_user_#{current_user.id}").click
  end

  step 'I view the user with secondary email' do
    @user_with_secondary_email = User.last
    @user_with_secondary_email.emails.new(email: "secondary@example.com")
    @user_with_secondary_email.save
    visit "/admin/users/#{@user_with_secondary_email.username}"
  end

  step 'I see the secondary email' do
    page.should have_content "Secondary email: #{@user_with_secondary_email.emails.last.email}"
  end

  step 'I click remove secondary email' do
    find("#remove_email_#{@user_with_secondary_email.emails.last.id}").click
  end

  step 'I should not see secondary email anymore' do
    page.should_not have_content "Secondary email:"
  end

  step 'user "Mike" with groups and projects' do
    user = create(:user, name: 'Mike')

    project = create(:empty_project)
    project.team << [user, :developer]

    group = create(:group)
    group.add_user(user, Gitlab::Access::DEVELOPER)
  end

  step 'click on "Mike" link' do
    click_link "Mike"
  end

  step 'I should see user "Mike" details' do
    page.should have_content 'Account'
    page.should have_content 'Personal projects limit'
  end

  step 'user "Pete" with ssh keys' do
    user = create(:user, name: 'Pete')
    create(:key, user: user, title: "ssh-rsa Key1", key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4FIEBXGi4bPU8kzxMefudPIJ08/gNprdNTaO9BR/ndy3+58s2HCTw2xCHcsuBmq+TsAqgEidVq4skpqoTMB+Uot5Uzp9z4764rc48dZiI661izoREoKnuRQSsRqUTHg5wrLzwxlQbl1MVfRWQpqiz/5KjBC7yLEb9AbusjnWBk8wvC1bQPQ1uLAauEA7d836tgaIsym9BrLsMVnR4P1boWD3Xp1B1T/ImJwAGHvRmP/ycIqmKdSpMdJXwxcb40efWVj0Ibbe7ii9eeoLdHACqevUZi6fwfbymdow+FeqlkPoHyGg3Cu4vD/D8+8cRc7mE/zGCWcQ15Var83Tczour Key1")
    create(:key, user: user, title: "ssh-rsa Key2", key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQSTWXhJAX/He+nG78MiRRRn7m0Pb0XbcgTxE0etArgoFoh9WtvDf36HG6tOSg/0UUNcp0dICsNAmhBKdncp6cIyPaXJTURPRAGvhI0/VDk4bi27bRnccGbJ/hDaUxZMLhhrzY0r22mjVf8PF6dvv5QUIQVm1/LeaWYsHHvLgiIjwrXirUZPnFrZw6VLREoBKG8uWvfSXw1L5eapmstqfsME8099oi+vWLR8MgEysZQmD28M73fgW4zek6LDQzKQyJx9nB+hJkKUDvcuziZjGmRFlNgSA2mguERwL1OXonD8WYUrBDGKroIvBT39zS5d9tQDnidEJZ9Y8gv5ViYP7x Key2")
  end

  step 'click on user "Pete"' do
    click_link 'Pete'
  end

  step 'I should see key list' do
    page.should have_content 'ssh-rsa Key2'
    page.should have_content 'ssh-rsa Key1'
  end

  step 'I click on the key title' do
    click_link 'ssh-rsa Key2'
  end

  step 'I should see key details' do
    page.should have_content 'ssh-rsa Key2'
    page.should have_content 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQSTWXhJAX/He+nG78MiRRRn7m0Pb0XbcgTxE0etArgoFoh9WtvDf36HG6tOSg/0UUNcp0dICsNAmhBKdncp6cIyPaXJTURPRAGvhI0/VDk4bi27bRnccGbJ/hDaUxZMLhhrzY0r22mjVf8PF6dvv5QUIQVm1/LeaWYsHHvLgiIjwrXirUZPnFrZw6VLREoBKG8uWvfSXw1L5eapmstqfsME8099oi+vWLR8MgEysZQmD28M73fgW4zek6LDQzKQyJx9nB+hJkKUDvcuziZjGmRFlNgSA2mguERwL1OXonD8WYUrBDGKroIvBT39zS5d9tQDnidEJZ9Y8gv5ViYP7x Key2'
  end

  step 'I click on remove key' do
    click_link 'Remove'
  end

  step 'I should see the key removed' do
    page.should_not have_content 'ssh-rsa Key2'
  end
end
