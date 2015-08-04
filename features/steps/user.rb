class Spinach::Features::User < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include SharedProject

  step 'I should see user "John Doe" page' do
    expect(title).to match(/^\s*John Doe/)
  end

  step '"John Doe" has contributions' do
    user = User.find_by(name: 'John Doe')
    project = contributed_project

    # Issue controbution
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
    page.within '.contributed-projects' do
      expect(page).to have_content(@contributed_project.name)
    end
  end

  step 'I should see contributions calendar' do
    expect(page).to have_css('.cal-heatmap-container')
  end

  def contributed_project
    @contributed_project ||= create(:project, :public)
  end
end
