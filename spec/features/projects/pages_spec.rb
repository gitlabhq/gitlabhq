require 'spec_helper'

feature 'Pages' do
  given(:project) { create(:empty_project) }
  given(:user) { create(:user) }
  given(:role) { :master }

  background do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

    project.team << [user, role]

    sign_in(user)
  end

  shared_examples 'no pages deployed' do
    scenario 'does not see anything to destroy' do
      visit project_pages_path(project)

      expect(page).not_to have_link('Remove pages')
      expect(page).not_to have_text('Only the project owner can remove pages')
    end
  end

  context 'when user is the owner' do
    background do
      project.namespace.update(owner: user)
    end

    context 'when pages deployed' do
      background do
        allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
      end

      scenario 'sees "Remove pages" link' do
        visit project_pages_path(project)

        expect(page).to have_link('Remove pages')
      end
    end

    it_behaves_like 'no pages deployed'
  end

  context 'when the user is not the owner' do
    context 'when pages deployed' do
      background do
        allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
      end

      scenario 'sees "Only the project owner can remove pages" text' do
        visit project_pages_path(project)

        expect(page).to have_text('Only the project owner can remove pages')
      end
    end

    it_behaves_like 'no pages deployed'
  end
end
