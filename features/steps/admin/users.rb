class Spinach::Features::AdminUsers < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  before do
    allow(Gitlab::OAuth::Provider).to receive(:providers).and_return([:twitter, :twitter_updated])
    allow_any_instance_of(ApplicationHelper).to receive(:user_omniauth_authorize_path).and_return(root_path)
  end

  after do
    allow(Gitlab::OAuth::Provider).to receive(:providers).and_call_original
    allow_any_instance_of(ApplicationHelper).to receive(:user_omniauth_authorize_path).and_call_original
  end

  step 'I should see all users' do
    User.all.each do |user|
      expect(page).to have_content user.name
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
    page.within "#error_explanation" do
      expect(page).to have_content "Username"
    end
  end

  step 'Not changed form action url' do
    expect(page).to have_selector %(form[action="/admin/users/#{@user.username}"])
  end

  step 'I submit modified user' do
    check :user_can_create_group
    click_button 'Save'
  end

  step 'I see user attributes changed' do
    expect(page).to have_content 'Can create groups: Yes'
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
    expect(page).to have_content "Secondary email: #{@user_with_secondary_email.emails.last.email}"
  end

  step 'I click remove secondary email' do
    find("#remove_email_#{@user_with_secondary_email.emails.last.id}").click
  end

  step 'I should not see secondary email anymore' do
    expect(page).not_to have_content "Secondary email:"
  end

  step 'user "Mike" with groups and projects' do
    user = create(:user, name: 'Mike')

    project = create(:empty_project)
    project.team << [user, :developer]

    group = create(:group)
    group.add_developer(user)
  end

  step 'click on "Mike" link' do
    click_link "Mike"
  end

  step 'I should see user "Mike" details' do
    expect(page).to have_content 'Account'
    expect(page).to have_content 'Personal projects limit'
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
    expect(page).to have_content 'ssh-rsa Key2'
    expect(page).to have_content 'ssh-rsa Key1'
  end

  step 'I click on the key title' do
    click_link 'ssh-rsa Key2'
  end

  step 'I should see key details' do
    expect(page).to have_content 'ssh-rsa Key2'
    expect(page).to have_content 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQSTWXhJAX/He+nG78MiRRRn7m0Pb0XbcgTxE0etArgoFoh9WtvDf36HG6tOSg/0UUNcp0dICsNAmhBKdncp6cIyPaXJTURPRAGvhI0/VDk4bi27bRnccGbJ/hDaUxZMLhhrzY0r22mjVf8PF6dvv5QUIQVm1/LeaWYsHHvLgiIjwrXirUZPnFrZw6VLREoBKG8uWvfSXw1L5eapmstqfsME8099oi+vWLR8MgEysZQmD28M73fgW4zek6LDQzKQyJx9nB+hJkKUDvcuziZjGmRFlNgSA2mguERwL1OXonD8WYUrBDGKroIvBT39zS5d9tQDnidEJZ9Y8gv5ViYP7x Key2'
  end

  step 'I click on remove key' do
    click_link 'Remove'
  end

  step 'I should see the key removed' do
    expect(page).not_to have_content 'ssh-rsa Key2'
  end

  step 'user "Pete" with twitter account' do
    @user = create(:user, name: 'Pete')
    @user.identities.create!(extern_uid: '123456', provider: 'twitter')
  end

  step 'I visit "Pete" identities page in admin' do
    visit admin_user_identities_path(@user)
  end

  step 'I should see twitter details' do
    expect(page).to have_content 'Pete'
    expect(page).to have_content 'twitter'
  end

  step 'I modify twitter identity' do
    find('.table').find(:link, 'Edit').click
    fill_in 'identity_extern_uid', with: '654321'
    select 'twitter_updated', from: 'identity_provider'
    click_button 'Save changes'
  end

  step 'I should see twitter details updated' do
    expect(page).to have_content 'Pete'
    expect(page).to have_content 'twitter_updated'
    expect(page).to have_content '654321'
  end

  step 'I remove twitter identity' do
    click_link 'Delete'
  end

  step 'I should not see twitter details' do
    expect(page).to have_content 'Pete'
    expect(page).not_to have_content 'twitter'
  end

  step 'click on ssh keys tab' do
    click_link 'SSH keys'
  end

  step 'I submit a note' do
    @note = 'The reason to change status'
    fill_in 'Note', with: @note
    click_button 'Save'
  end

  step 'I see note tooltip' do
    visit admin_users_path
    expect(find(".user-note")["title"]).to have_content(@note)
  end
end
