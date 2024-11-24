# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE', :js, :with_current_organization, feature_category: :web_ide do
  include Features::WebIdeSpecHelpers

  let_it_be(:ide_iframe_selector) { '#ide iframe' }
  let_it_be(:normal_project) { create(:project, :repository) }

  let(:project) { normal_project }
  let(:user) { create(:user, organizations: [current_organization]) }

  before do
    # TODO - We need to be able to handle requests to https://*.cdn.web-ide.gitlab-static.net
    #        in order to support `web_ide_extensions_marketplace` in our feature specs.
    #        https://gitlab.com/gitlab-org/gitlab/-/issues/478626
    stub_feature_flags(web_ide_extensions_marketplace: false)

    project.add_maintainer(user)
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
      iframe = find(ide_iframe_selector)

      page.within_frame(iframe) do
        expect(page).to have_selector('.title', text: project.path.upcase)

        # Verify that the built-in GitLab Workflow Extension loads
        expect(page).to have_css('#GitLab\\.gitlab-workflow\\.gl\\.status\\.code_suggestions')
      end

      expect_page_to_have_no_console_errors
    end
  end

  describe 'with sub-groups' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:subgroup_project) { create(:project, :repository, namespace: subgroup) }

    let(:project) { subgroup_project }

    before do
      stub_feature_flags(vscode_web_ide: true)

      ide_visit(project)
    end

    it_behaves_like 'new Web IDE'
  end

  describe 'with vscode feature flag off' do
    before do
      stub_feature_flags(vscode_web_ide: false)

      ide_visit(project)
    end

    it_behaves_like 'legacy Web IDE'
  end
end
