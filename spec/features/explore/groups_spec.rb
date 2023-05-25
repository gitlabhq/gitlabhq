# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Explore Groups', :js, feature_category: :groups_and_projects do
  let(:user) { create :user }
  let(:group) { create :group }
  let!(:private_project) do
    create :project, :private, namespace: group do |project|
      create(:issue, project: internal_project)
      create(:merge_request, source_project: project, target_project: project)
    end
  end

  let!(:internal_project) do
    create :project, :internal, namespace: group do |project|
      create(:issue, project: project)
      create(:merge_request, source_project: project, target_project: project)
    end
  end

  let!(:public_project) do
    create(:project, :public, namespace: group) do |project|
      create(:issue, project: project)
      create(:merge_request, source_project: project, target_project: project)
    end
  end

  shared_examples 'renders public and internal projects' do
    it do
      visit_page
      expect(page).to have_content(public_project.name).or(have_content(public_project.path))
      expect(page).to have_content(internal_project.name).or(have_content(internal_project.path))
      expect(page).not_to have_content(private_project.name)
    end
  end

  shared_examples 'renders only public project' do
    it do
      visit_page
      expect(page).to have_content(public_project.name).or(have_content(public_project.path))
      expect(page).not_to have_content(internal_project.name)
      expect(page).not_to have_content(private_project.name)
    end
  end

  shared_examples 'renders group in public groups area' do
    it do
      visit explore_groups_path
      expect(page).to have_content(group.path)
    end
  end

  context 'when signed in' do
    before do
      sign_in(user)
    end

    context 'for group_path' do
      it_behaves_like 'renders public and internal projects' do
        subject(:visit_page) { visit group_path(group) }
      end
    end

    context 'for issues_group_path' do
      it_behaves_like 'renders public and internal projects' do
        subject(:visit_page) { visit issues_group_path(group) }
      end
    end

    context 'for merge_requests_group_path' do
      it_behaves_like 'renders public and internal projects' do
        subject(:visit_page) { visit merge_requests_group_path(group) }
      end
    end

    it_behaves_like 'renders group in public groups area'
  end

  context 'when signed out' do
    context 'for group_path' do
      it_behaves_like 'renders only public project' do
        subject(:visit_page) { visit group_path(group) }
      end
    end

    context 'for issues_group_path' do
      it_behaves_like 'renders only public project' do
        subject(:visit_page) { visit issues_group_path(group) }
      end
    end

    context 'for merge_requests_group_path' do
      it_behaves_like 'renders only public project' do
        subject(:visit_page) { visit merge_requests_group_path(group) }
      end
    end

    it_behaves_like 'renders group in public groups area'

    context 'when visibility is restricted to public' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'redirects to the sign in page' do
        visit explore_groups_path

        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end
end
