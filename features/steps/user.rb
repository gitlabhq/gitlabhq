class Spinach::Features::User < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include SharedProject

  step 'I should see user "John Doe" page' do
    expect(title).to match(/^\s*John Doe/)
  end

  step 'I visit unsubscribe link' do
    email = Base64.urlsafe_encode64("joh@doe.org")
    visit "/unsubscribes/#{email}"
  end

  step 'I should see unsubscribe text and button' do
    expect(page).to have_content "Unsubscribe from Admin notifications Yes, I want to unsubscribe joh@doe.org from any further admin emails."
  end

  step 'I press the unsubscribe button' do
    click_button("Unsubscribe")
  end

  step 'I should be unsubscribed' do
    expect(current_path).to eq root_path
  end

  step '"John Doe" has contributions' do
    user = User.find_by(name: 'John Doe')
    project = contributed_project

    # Issue contribution
    issue_params = { title: 'Bug in old browser' }
    Issues::CreateService.new(project, user, issue_params).execute

    # Push code contribution
    push_params = {
      project: project,
      action: Event::PUSHED,
      author_id: user.id,
      data: { commit_count: 3 }
    }

    Event.create(push_params)
  end

  step 'I should see contributed projects' do
    page.within '#contributed' do
      expect(page).to have_content(@contributed_project.name)
    end
  end

  step 'I should see contributions calendar' do
    expect(page).to have_css('.js-contrib-calendar')
  end

  def contributed_project
    @contributed_project ||= create(:project, :public)
  end
end
