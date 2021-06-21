# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users > User browses projects on user page', :js do
  let!(:user) { create :user }
  let!(:private_project) do
    create :project, :private, name: 'private', namespace: user.namespace do |project|
      project.add_maintainer(user)
    end
  end

  let!(:internal_project) do
    create :project, :internal, name: 'internal', namespace: user.namespace do |project|
      project.add_maintainer(user)
    end
  end

  let!(:public_project) do
    create :project, :public, name: 'public', namespace: user.namespace do |project|
      project.add_maintainer(user)
    end
  end

  def click_nav_link(name)
    page.within '.nav-links' do
      click_link name
    end
  end

  it 'hides loading spinner after load', :js do
    visit user_path(user)
    click_nav_link('Personal projects')

    wait_for_requests

    expect(page).not_to have_selector('.loading-status .loading', visible: true)
  end

  it 'paginates projects', :js do
    project = create(:project, namespace: user.namespace, updated_at: 2.minutes.since)
    project2 = create(:project, namespace: user.namespace, updated_at: 1.minute.since)
    allow(Project).to receive(:default_per_page).and_return(1)

    sign_in(user)
    visit user_path(user)
    click_nav_link('Personal projects')

    wait_for_requests

    expect(page).to have_content(project.name)

    click_link('Next')

    expect(page).to have_content(project2.name)
  end

  it 'does not have incorrectly interpolated message', :js do
    project = create(:project, namespace: user.namespace, updated_at: 2.minutes.since)

    sign_in(user)
    visit user_path(user)
    click_nav_link('Personal projects')

    wait_for_requests

    expect(page).to have_content(project.name)
    expect(page).not_to have_content("_('Updated')")
  end

  context 'when not signed in' do
    it 'renders user public project' do
      visit user_path(user)
      click_nav_link('Personal projects')

      expect(page).to have_css('.tab-content #projects.active')
      expect(title).to start_with(user.name)

      expect(page).to have_content(public_project.name)
      expect(page).not_to have_content(private_project.name)
      expect(page).not_to have_content(internal_project.name)
    end
  end

  context 'when signed in as another user' do
    let(:another_user) { create :user }

    before do
      sign_in(another_user)
    end

    it 'renders user public and internal projects' do
      visit user_path(user)
      click_nav_link('Personal projects')

      expect(title).to start_with(user.name)

      expect(page).not_to have_content(private_project.name)
      expect(page).to have_content(public_project.name)
      expect(page).to have_content(internal_project.name)
    end
  end

  context 'when signed in as user' do
    before do
      sign_in(user)
    end

    describe 'personal projects' do
      it 'renders all user projects' do
        visit user_path(user)
        click_nav_link('Personal projects')

        expect(title).to start_with(user.name)
        expect(page).to have_content(private_project.name)
        expect(page).to have_content(public_project.name)
        expect(page).to have_content(internal_project.name)
      end
    end

    describe 'contributed projects' do
      context 'when user has contributions' do
        let(:contributed_project) do
          create :project, :public, :empty_repo
        end

        before do
          Issues::CreateService.new(project: contributed_project, current_user: user, params: { title: 'Bug in old browser' }, spam_params: nil).execute
          event = create(:push_event, project: contributed_project, author: user)
          create(:push_event_payload, event: event, commit_count: 3)
        end

        it 'renders contributed project' do
          visit user_path(user)

          expect(title).to start_with(user.name)
          expect(page).to have_css('.js-contrib-calendar')

          click_nav_link('Contributed projects')

          page.within '#contributed' do
            expect(page).to have_content(contributed_project.name)
          end
        end
      end
    end
  end
end
