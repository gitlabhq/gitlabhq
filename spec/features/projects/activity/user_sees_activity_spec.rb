require 'spec_helper'

feature 'Projects > Activity > User sees activity' do
  let(:project) { create(:project, :repository, :public) }
  let(:user) { project.creator }

  before do
    event = create(:push_event, project: project, author: user)
    create(:push_event_payload,
           event: event,
           action: :created,
           commit_to: '6d394385cf567f80a8fd85055db1ab4c5295806f',
           ref: 'fix',
           commit_count: 1)
    visit activity_project_path(project)
  end

  it 'shows the last push in the activity page', :js do
    expect(page).to have_content "#{user.name} pushed new branch fix"
  end
end
