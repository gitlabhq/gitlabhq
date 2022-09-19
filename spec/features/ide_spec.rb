# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE', :js do
  describe 'sub-groups' do
    let(:ide_iframe_selector) { '#ide iframe' }
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:subgroup_project) { create(:project, :repository, namespace: subgroup) }

    before do
      stub_feature_flags(vscode_web_ide: vscode_ff)
      subgroup_project.add_maintainer(user)
      sign_in(user)

      visit project_path(subgroup_project)

      click_link('Web IDE')

      wait_for_requests
    end

    context 'with vscode feature flag on' do
      let(:vscode_ff) { true }

      it 'loads project in Web IDE' do
        iframe = find(ide_iframe_selector)

        page.within_frame(iframe) do
          expect(page).to have_selector('.title', text: subgroup_project.name.upcase)
        end
      end
    end

    context 'with vscode feature flag off' do
      let(:vscode_ff) { false }

      it 'loads project in legacy Web IDE' do
        expect(page).to have_selector('.context-header', text: subgroup_project.name)
      end

      it 'does not load new Web IDE' do
        expect(page).not_to have_selector(ide_iframe_selector)
      end
    end
  end
end
