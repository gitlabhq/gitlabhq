require 'spec_helper'

describe 'Explore Groups', :js do
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
      expect(page).to have_content(public_project.name)
      expect(page).to have_content(internal_project.name)
      expect(page).not_to have_content(private_project.name)
    end
  end

  shared_examples 'renders only public project' do
    it do
      visit_page
      expect(page).to have_content(public_project.name)
      expect(page).not_to have_content(internal_project.name)
      expect(page).not_to have_content(private_project.name)
    end
  end

  shared_examples 'renders group in public groups area' do
    it do
      visit explore_groups_path
      expect(page).to have_content(group.name)
    end
  end

  context 'when signed in' do
    before do
      sign_in(user)
    end

    it_behaves_like 'renders public and internal projects' do
      subject(:visit_page) { visit group_path(group) }
    end

    it_behaves_like 'renders public and internal projects' do
      subject(:visit_page) { visit issues_group_path(group) }
    end

    it_behaves_like 'renders public and internal projects' do
      subject(:visit_page) { visit merge_requests_group_path(group) }
    end

    it_behaves_like 'renders group in public groups area'
  end

  context 'when signed out' do
    it_behaves_like 'renders only public project' do
      subject(:visit_page) { visit group_path(group) }
    end

    it_behaves_like 'renders only public project' do
      subject(:visit_page) { visit issues_group_path(group) }
    end

    it_behaves_like 'renders only public project' do
      subject(:visit_page) { visit merge_requests_group_path(group) }
    end

    it_behaves_like 'renders group in public groups area'
  end
end
