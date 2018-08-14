require 'spec_helper'

describe 'Projects > Show > Collaboration links' do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'shows all the expected links' do
    visit project_path(project)

    # The navigation bar
    page.within('.header-new') do
      aggregate_failures 'dropdown links in the navigation bar' do
        expect(page).to have_link('New issue')
        expect(page).to have_link('New merge request')
        expect(page).to have_link('New snippet', href: new_project_snippet_path(project))
      end
    end

    # The project header
    page.within('.project-home-panel') do
      aggregate_failures 'dropdown links in the project home panel' do
        expect(page).to have_link('New issue')
        expect(page).to have_link('New merge request')
        expect(page).to have_link('New snippet')
        expect(page).to have_link('New file')
        expect(page).to have_link('New branch')
        expect(page).to have_link('New tag')
      end
    end

    # The dropdown above the tree
    page.within('.repo-breadcrumb') do
      aggregate_failures 'dropdown links above the repo tree' do
        expect(page).to have_link('New file')
        expect(page).to have_link('Upload file')
        expect(page).to have_link('New directory')
        expect(page).to have_link('New branch')
        expect(page).to have_link('New tag')
      end
    end

    # The Web IDE
    expect(page).to have_link('Web IDE')
  end

  it 'hides the links when the project is archived' do
    project.update!(archived: true)

    visit project_path(project)

    page.within('.header-new') do
      aggregate_failures 'dropdown links' do
        expect(page).not_to have_link('New issue')
        expect(page).not_to have_link('New merge request')
        expect(page).not_to have_link('New snippet', href: new_project_snippet_path(project))
      end
    end

    page.within('.project-home-panel') do
      aggregate_failures 'dropdown links' do
        expect(page).not_to have_link('New issue')
        expect(page).not_to have_link('New merge request')
        expect(page).not_to have_link('New snippet')
        expect(page).not_to have_link('New file')
        expect(page).not_to have_link('New branch')
        expect(page).not_to have_link('New tag')
      end
    end

    page.within('.repo-breadcrumb') do
      aggregate_failures 'dropdown links' do
        expect(page).not_to have_link('New file')
        expect(page).not_to have_link('Upload file')
        expect(page).not_to have_link('New directory')
        expect(page).not_to have_link('New branch')
        expect(page).not_to have_link('New tag')
      end
    end

    expect(page).not_to have_link('Web IDE')
  end
end
