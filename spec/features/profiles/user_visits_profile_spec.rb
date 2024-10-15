# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits their profile', feature_category: :user_profile do
  let_it_be_with_refind(:user) { create(:user) }

  before do
    stub_feature_flags(profile_tabs_vue: false)
    stub_feature_flags(edit_user_profile_vue: false)
    sign_in(user)
  end

  it 'shows profile info' do
    visit(user_settings_profile_path)

    expect(page).to have_content "This information will appear on your profile"
  end

  it 'shows user readme' do
    create(:project, :repository, :public, path: user.username, namespace: user.namespace)

    visit(user_path(user))

    expect(find('.file-content')).to have_content('testme')
  end

  it 'hides empty user readme' do
    project = create(:project, :repository, :public, path: user.username, namespace: user.namespace)

    Files::UpdateService.new(
      project,
      user,
      start_branch: 'master',
      branch_name: 'master',
      commit_message: 'Update feature',
      file_path: 'README.md',
      file_content: ''
    ).execute

    visit(user_path(user))

    expect(page).not_to have_selector('.file-content')
  end

  context 'for tabs' do
    shared_examples_for 'shows expected content' do
      it 'shows expected content', :js do
        visit(user_path(user))

        within_testid('user-profile-header') do
          expect(page).to have_content user.name
          expect(page).to have_content user.username
        end

        within_testid('super-sidebar') do
          click_link link
        end

        page.within div do
          expect(page).to have_content expected_content
        end
      end
    end

    context 'for Groups' do
      let_it_be(:group) do
        create :group do |group|
          group.add_owner(user)
        end
      end

      let_it_be(:project) do
        create(:project, :repository, namespace: group) do |project|
          create(:closed_issue_event, project: project)
          project.add_maintainer(user)
        end
      end

      it_behaves_like 'shows expected content' do
        let(:link) { 'Groups' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { group.name }
      end
    end

    context 'for Contributed projects' do
      let_it_be(:project) do
        create(:project) do |project|
          project.add_maintainer(user)
        end
      end

      before do
        push_event = create(:push_event, project: project, author: user)
        create(:push_event_payload, event: push_event)
      end

      it_behaves_like 'shows expected content' do
        let(:link) { 'Contributed projects' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { project.name }
      end
    end

    context 'for personal projects' do
      let_it_be(:project) do
        create(:project, namespace: user.namespace)
      end

      it_behaves_like 'shows expected content' do
        let(:link) { 'Personal projects' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { project.name }
      end
    end

    context 'for starred projects' do
      let_it_be(:project) { create(:project, :public) }

      before do
        user.toggle_star(project)
      end

      it_behaves_like 'shows expected content' do
        let(:link) { 'Starred projects' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { project.name }
      end
    end

    context 'for snippets' do
      let_it_be(:snippet) { create(:personal_snippet, :public, author: user) }

      it_behaves_like 'shows expected content' do
        let(:link) { 'Snippets' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { snippet.title }
      end
    end

    context 'for followers' do
      let_it_be(:fan) { create(:user) }

      before do
        fan.follow(user)
      end

      it_behaves_like 'shows expected content' do
        let(:link) { 'Followers' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { fan.name }
      end
    end

    context 'for following' do
      let_it_be(:star) { create(:user) }

      before do
        user.follow(star)
      end

      it_behaves_like 'shows expected content' do
        let(:link) { 'Following' }
        let(:div) { '#js-legacy-tabs-container' }
        let(:expected_content) { star.name }
      end
    end
  end
end
