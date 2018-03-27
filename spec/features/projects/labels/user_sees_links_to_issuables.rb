require 'spec_helper'

feature 'Projects > Labels > User sees links to issuables' do
  set(:user) { create(:user) }

  before do
    label # creates the label
    project.add_developer(user)
    sign_in user
    visit project_labels_path(project)
  end

  context 'with a project label' do
    let(:label) { create(:label, project: project, title: 'bug') }

    context 'when merge requests and issues are enabled for the project' do
      let(:project) { create(:project, :public) }

      scenario 'shows links to MRs and issues' do
        expect(page).to have_link('view merge requests')
        expect(page).to have_link('view open issues')
      end
    end

    context 'when issues are disabled for the project' do
      let(:project) { create(:project, :public, issues_access_level: ProjectFeature::DISABLED) }

      scenario 'shows links to MRs but not to issues' do
        expect(page).to have_link('view merge requests')
        expect(page).not_to have_link('view open issues')
      end
    end

    context 'when merge requests are disabled for the project' do
      let(:project) { create(:project, :public, merge_requests_access_level: ProjectFeature::DISABLED) }

      scenario 'shows links to issues but not to MRs' do
        expect(page).not_to have_link('view merge requests')
        expect(page).to have_link('view open issues')
      end
    end
  end

  context 'with a group label' do
    set(:group) { create(:group) }
    let(:label) { create(:group_label, group: group, title: 'bug') }

    context 'when merge requests and issues are enabled for the project' do
      let(:project) { create(:project, :public, namespace: group) }

      scenario 'shows links to MRs and issues' do
        expect(page).to have_link('view merge requests')
        expect(page).to have_link('view open issues')
      end
    end

    context 'when issues are disabled for the project' do
      let(:project) { create(:project, :public, namespace: group, issues_access_level: ProjectFeature::DISABLED) }

      scenario 'shows links to MRs and issues' do
        expect(page).to have_link('view merge requests')
        expect(page).to have_link('view open issues')
      end
    end

    context 'when merge requests are disabled for the project' do
      let(:project) { create(:project, :public, namespace: group, merge_requests_access_level: ProjectFeature::DISABLED) }

      scenario 'shows links to MRs and issues' do
        expect(page).to have_link('view merge requests')
        expect(page).to have_link('view open issues')
      end
    end
  end
end
