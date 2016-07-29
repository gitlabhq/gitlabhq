class Spinach::Features::AdminEmail < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I submit form with email notification info' do
    perform_enqueued_jobs do
      ActionMailer::Base.deliveries = []
      @email_text = "Your project has been moved."
      @selected_group = Group.last
      # ensure there are ppl to be emailed
      2.times do
        @selected_group.add_user(create(:user), Gitlab::Access::DEVELOPER)
      end

      page.within('form#new-admin-email') do
        fill_in :subject, with: 'my subject'
        fill_in :body, with: @email_text

        # Note: Unable to use select2 helper because
        # the helper uses select2 method "val" to select the group from the dropdown
        # and the method "val" requires "initSelection" to be used in the select2 call
        select2_container = first("#s2id_recipients")
        select2_container.find(".select2-choice").click
        find(:xpath, "//body").find("input.select2-input").set(@selected_group.name)
        page.execute_script(%|$("input.select2-input:visible").keyup();|)
        find(:xpath, "//body").find(".group-name", text: @selected_group.name).click

        find('.btn-create').click
      end
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
    perform_enqueued_jobs do
      click_button 'Unsubscribe'
    end
  end

  step 'I get redirected to the sign in path' do
    expect(current_path).to eq root_path
  end

  step 'unsubscribed email is sent' do
    mail = ActionMailer::Base.deliveries.last
    expect(mail.text_part.body.decoded).to include "You have been unsubscribed from receiving GitLab administrator notifications."
  end
end
