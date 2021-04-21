# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Labels > User sees links to issuables' do
  let_it_be(:user) { create(:user) }

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

      it 'shows links to MRs and issues' do
        page.within('.labels-container') do
          expect(page).to have_link('Merge requests')
          expect(page).to have_link('Issues')
        end
      end
    end

    context 'when issues are disabled for the project' do
      let(:project) { create(:project, :public, issues_access_level: ProjectFeature::DISABLED) }

      it 'shows links to MRs but not to issues' do
        page.within('.labels-container') do
          expect(page).to have_link('Merge requests')
          expect(page).not_to have_link('Issues')
        end
      end
    end

    context 'when merge requests are disabled for the project' do
      let(:project) { create(:project, :public, merge_requests_access_level: ProjectFeature::DISABLED) }

      it 'shows links to issues but not to MRs' do
        page.within('.labels-container') do
          expect(page).not_to have_link('Merge requests')
          expect(page).to have_link('Issues')
        end
      end
    end
  end

  context 'with a group label' do
    let_it_be(:group) { create(:group) }

    let(:label) { create(:group_label, group: group, title: 'bug') }

    context 'when merge requests and issues are enabled for the project' do
      let(:project) { create(:project, :public, namespace: group) }

      it 'shows links to MRs and issues' do
        page.within('.labels-container') do
          expect(page).to have_link('Merge requests')
          expect(page).to have_link('Issues')
        end
      end
    end

    context 'when issues are disabled for the project' do
      let(:project) { create(:project, :public, namespace: group, issues_access_level: ProjectFeature::DISABLED) }

      it 'shows links to MRs and issues' do
        page.within('.labels-container') do
          expect(page).to have_link('Merge requests')
          expect(page).to have_link('Issues')
        end
      end
    end

    context 'when merge requests are disabled for the project' do
      let(:project) { create(:project, :public, namespace: group, merge_requests_access_level: ProjectFeature::DISABLED) }

      it 'shows links to MRs and issues' do
        page.within('.labels-container') do
          expect(page).to have_link('Merge requests')
          expect(page).to have_link('Issues')
        end
      end
    end
  end
end
