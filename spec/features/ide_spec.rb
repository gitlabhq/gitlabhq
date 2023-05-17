# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE', :js, feature_category: :web_ide do
  include Features::WebIdeSpecHelpers

  let_it_be(:ide_iframe_selector) { '#ide iframe' }
  let_it_be(:normal_project) { create(:project, :repository) }

  let(:project) { normal_project }
  let(:vscode_ff) { false }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    stub_feature_flags(vscode_web_ide: vscode_ff)

    sign_in(user)
  end

  shared_examples "legacy Web IDE" do
    it 'loads legacy Web IDE', :aggregate_failures do
      expect(page).to have_selector('.context-header', text: project.name)

      # Assert new Web IDE is not loaded
      expect(page).not_to have_selector(ide_iframe_selector)
    end
  end

  shared_examples "new Web IDE" do
    it 'loads new Web IDE', :aggregate_failures do
      expect(page).not_to have_selector('.context-header')

      iframe = find(ide_iframe_selector)

      page.within_frame(iframe) do
        expect(page).to have_selector('.title', text: project.name.upcase)
      end
    end
  end

  context 'with vscode feature flag off' do
    before do
      ide_visit(project)
    end

    it_behaves_like 'legacy Web IDE'
  end

  describe 'sub-groups' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:subgroup_project) { create(:project, :repository, namespace: subgroup) }

    let(:project) { subgroup_project }

    before do
      ide_visit(project)
    end

    it_behaves_like 'legacy Web IDE'
  end
end
