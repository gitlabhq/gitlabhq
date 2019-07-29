# frozen_string_literal: true

require 'spec_helper'

describe 'Merge Request > Tries to access private repo of public project' do
  let(:current_user) { create(:user) }
  let(:private_project) do
    create(:project, :public, :repository,
           path: 'nothing-to-see-here',
           name: 'nothing to see here',
           repository_access_level: ProjectFeature::PRIVATE)
  end
  let(:owned_project) do
    create(:project, :public, :repository,
           namespace: current_user.namespace,
           creator: current_user)
  end

  context 'when the user enters the querystring info for the other project' do
    let(:mr_path) do
      project_new_merge_request_diffs_path(
        owned_project,
        merge_request: {
          source_project_id: private_project.id,
          source_branch: 'feature'
        }
      )
    end

    before do
      sign_in current_user
      visit mr_path
    end

    it "does not mention the project the user can't see the repo of" do
      expect(page).not_to have_content('nothing-to-see-here')
    end
  end
end
