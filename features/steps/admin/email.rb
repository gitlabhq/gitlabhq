class Spinach::Features::AdminEmail < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I submit form with email notification info' do
    @email_text = "I've moved the project"
    @selected_project = Group.last.projects.first
    within('form#new-admin-email') do
      fill_in :subject, with: 'my subject'
      fill_in :body, with: @email_text
      select "#{@selected_project.group.name} / #{@selected_project.name}", from: :recipients
      find('.btn-create').click
    end
  end

  step 'I should see a notification email is begin send' do
    expect(find('.flash-notice')).to have_content 'Email send'
  end
end