# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'viewing issues with design references', feature_category: :design_management do
  include DesignManagementTestHelpers

  # Ensure support bot user is created so creation doesn't count towards query limit
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
  let_it_be(:support_bot) { Users::Internal.support_bot }

  let_it_be(:public_project) { create(:project_empty_repo, :public) }
  let_it_be(:private_project) { create(:project_empty_repo) }

  let(:user) { create(:user) }
  let(:design_issue) { create(:issue, project: project) }
  let(:design_a) { create(:design, :with_file, issue: design_issue) }
  let(:design_b) { create(:design, :with_file, issue: design_issue) }
  let(:issue_ref) { design_issue.to_reference(public_project) }
  let(:design_ref_a) { design_a.to_reference(public_project) }
  let(:design_ref_b) { design_b.to_reference(public_project) }
  let(:design_tab_ref) { "#{issue_ref} (designs)" }

  let(:description) do
    <<~MD
    The designs I mentioned:

    * #{url_for_designs(design_issue)}
    * #{url_for_design(design_a)}
    * #{url_for_design(design_b)}
    MD
  end

  def visit_page_with_design_references
    public_issue = create(:issue, project: public_project, description: description)
    visit project_issue_path(public_issue.project, public_issue)
  end

  shared_examples 'successful use of design link references' do
    before do
      enable_design_management
    end

    it 'shows the issue description and design references', :aggregate_failures do
      visit_page_with_design_references

      expect(page).to have_text('The designs I mentioned')
      expect(page).to have_link(design_tab_ref)
      expect(page).to have_link(design_ref_a)
      expect(page).to have_link(design_ref_b)
    end
  end

  context 'the user has access to a public project' do
    let(:project) { public_project }

    it_behaves_like 'successful use of design link references'
  end

  context 'the user does not have access to a private project' do
    let(:project) { private_project }

    it 'redacts inaccessible design references', :aggregate_failures do
      visit_page_with_design_references

      expect(page).to have_text('The designs I mentioned')
      expect(page).not_to have_link(issue_ref)
      expect(page).not_to have_link(design_tab_ref)
      expect(page).not_to have_link(design_ref_a)
      expect(page).not_to have_link(design_ref_b)
    end
  end

  context 'the user has access to a private project' do
    let(:project) { private_project }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    it_behaves_like 'successful use of design link references'

    context 'design management is entirely disabled' do
      it 'processes design links as issue references', :aggregate_failures do
        enable_design_management(false)

        visit_page_with_design_references

        expect(page).to have_text('The designs I mentioned')
        expect(page).to have_link(issue_ref)
        expect(page).not_to have_link(design_tab_ref)
        expect(page).not_to have_link(design_ref_a)
        expect(page).not_to have_link(design_ref_b)
      end
    end
  end
end
