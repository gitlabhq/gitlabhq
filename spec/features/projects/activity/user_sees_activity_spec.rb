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

  shared_examples 'push appears in activity' do
    it 'shows the last push in the activity page', :js do
      expect(page).to have_content "#{user.name} pushed new branch fix"
    end
  end

  context 'when signed in' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    it_behaves_like 'push appears in activity'
  end

  context 'when signed out' do
    it_behaves_like 'push appears in activity'
  end
end
