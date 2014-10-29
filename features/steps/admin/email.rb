class Spinach::Features::AdminEmail < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I submit form with email notification info' do
    ActionMailer::Base.deliveries = []
    @email_text = "Your project has been moved."
    @selected_group = Group.last
    # ensure there are ppl to be emailed
    2.times do
      @selected_group.add_user(create(:user), Gitlab::Access::DEVELOPER)
    end

    within('form#new-admin-email') do
      fill_in :subject, with: 'my subject'
      fill_in :body, with: @email_text
      select @selected_group.name, from: :recipients
      find('.btn-create').click
    end
  end

  step 'I should see a notification email is begin sent' do
    expect(find('.flash-notice')).to have_content 'Email sent'
  end

  step 'admin emails are being sent' do
    expect(ActionMailer::Base.deliveries.count).to eql @selected_group.users.count
    mail = ActionMailer::Base.deliveries.last
    expect(mail.text_part.body.decoded).to include @email_text
  end

  step 'I visit unsubscribe from admin notification page' do
    @user = create(:user)
    urlsafe_email = Base64.urlsafe_encode64(@user.email)
    visit unsubscribe_path(urlsafe_email)
  end

  step 'I click unsubscribe' do
    click_button 'Unsubscribe'
  end

  step 'I get redirected to the sign in path' do
    current_path.should == root_path
  end

  step 'unsubscribed email is sent' do
    mail = ActionMailer::Base.deliveries.last
    expect(mail.text_part.body.decoded).to include "You have been unsubscribed from receiving GitLab administrator notifications."
  end
end
