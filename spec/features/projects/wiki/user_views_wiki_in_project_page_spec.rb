require 'spec_helper'

describe 'Projects > Wiki > User views wiki in project page', feature: true do
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  context 'when repository is disabled for project' do
    let(:project) do
      create(:empty_project,
             :repository_disabled,
             :merge_requests_disabled,
             :builds_disabled)
    end

    context 'when wiki homepage contains a link' do
      before do
        WikiPages::CreateService.new(
          project,
          user,
          title: 'home',
          content: '[some link](other-page)'
        ).execute
      end

      it 'displays the correct URL for the link' do
        visit project_path(project)
        expect(page).to have_link(
          'some link',
          href: project_wiki_path(project, 'other-page')
        )
      end
    end
  end
end
