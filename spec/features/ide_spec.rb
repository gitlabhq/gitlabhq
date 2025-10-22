# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE', :js, :with_current_organization, feature_category: :web_ide,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/539416' do
  include Features::WebIdeSpecHelpers

  let_it_be(:normal_project) { create(:project, :repository) }

  let(:project) { normal_project }
  let(:user) { create(:user, organizations: [current_organization]) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples "Web IDE" do
    it 'loads Web IDE', :aggregate_failures do
      within_web_ide do
        expect(page).to have_text(project.path.upcase)
        # Verify that the built-in GitLab Workflow Extension loads
        expect(page).to have_css('#GitLab\\.gitlab-workflow\\.gl\\.status\\.code_suggestions')
      end

      expect_page_to_have_no_console_errors
    end
  end

  where(:directory_code_dropdown_updates) do
    [true, false]
  end

  with_them do
    describe 'with sub-groups' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_project) { create(:project, :repository, namespace: subgroup) }

      let(:project) { subgroup_project }

      before do
        stub_feature_flags(directory_code_dropdown_updates: directory_code_dropdown_updates)

        ide_visit(project)
      end

      it_behaves_like 'Web IDE'
    end
  end
end
