# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'viewing an issue with cross project references', :js, feature_category: :team_planning do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_project) do
    create(:project, :public, external_authorization_classification_label: 'other_label')
  end

  let_it_be(:other_issue) do
    create(:issue, :closed, title: 'I am in another project', project: other_project)
  end

  let_it_be(:other_confidential_issue) do
    create(:issue, :confidential, :closed, title: 'I am in another project and confidential', project: other_project)
  end

  let_it_be(:other_merge_request) do
    create(:merge_request, :closed, title: 'I am a merge request in another project', source_project: other_project)
  end

  let_it_be(:project) { create(:project) }

  let_it_be(:confidential_issue) do
    create(:issue, :confidential, :closed, title: "I am in the same project and confidential", project: project)
  end

  let_it_be(:issue) do
    description_referencing_other_issue = "Referencing: #{other_issue.to_reference(project)}, "\
                                          "a confidential issue #{confidential_issue.to_reference}, "\
                                          "a cross project confidential issue #{other_confidential_issue.to_reference(project)}, and "\
                                          "a cross project merge request #{other_merge_request.to_reference(project)}"
    create(:issue, project: project, description: description_referencing_other_issue)
  end

  before_all do
    project.add_developer(user)
  end

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    sign_in(user)
  end

  it 'shows all references the user has access to', :aggregate_failures do
    visit project_issue_path(project, issue)

    # cross-project issue and MR references
    expect(page).to have_link("#{other_issue.to_reference(project)} (#{other_issue.state})")
    expect(page).to have_xpath("//a[@title='#{other_issue.title}']")
    expect(page).to have_link("#{other_merge_request.to_reference(project)} (#{other_merge_request.state})")
    expect(page).to have_xpath("//a[@title='#{other_merge_request.title}']")

    # confidential issue in same project
    expect(page).to have_link("#{confidential_issue.to_reference(project)} (#{confidential_issue.state})")
    expect(page).to have_xpath("//a[@title='#{confidential_issue.title}']")

    # confidential issue in other project user does not have access to
    expect(page).not_to have_link(other_confidential_issue.to_reference(project))
    expect(page).not_to have_xpath("//a[@title='#{other_confidential_issue.title}']")
  end

  it 'shows the link to a cross project confidential issue when the user has access' do
    other_project.add_developer(user)

    visit project_issue_path(project, issue)

    expect(page).to have_link("#{other_confidential_issue.to_reference(project)} (#{other_confidential_issue.state})")
    expect(page).to have_xpath("//a[@title='#{other_confidential_issue.title}']")
  end

  context 'when an external authorization service is enabled' do
    before do
      enable_external_authorization_service_check
    end

    it 'only hits the external service for the project the user is viewing' do
      expect(::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'default_label', any_args).at_least(1).and_return(true)
      expect(::Gitlab::ExternalAuthorization)
        .not_to receive(:access_allowed?).with(user, 'other_label', any_args)

      visit project_issue_path(project, issue)
    end

    it 'redacts the cross project references', :aggregate_failures do
      visit project_issue_path(project, issue)

      # cross-project issue and MR references
      expect(page).not_to have_link(other_issue.to_reference(project))
      expect(page).not_to have_xpath("//a[@title='#{other_issue.title}']")
      expect(page).not_to have_link(other_merge_request.to_reference(project))
      expect(page).not_to have_xpath("//a[@title='#{other_merge_request.title}']")

      # confidential issue in same project
      expect(page).to have_link("#{confidential_issue.to_reference(project)} (#{confidential_issue.state})")
      expect(page).to have_xpath("//a[@title='#{confidential_issue.title}']")

      # confidential issue in other project user does not have access to
      expect(page).not_to have_link(other_confidential_issue.to_reference(project))
      expect(page).not_to have_xpath("//a[@title='#{other_confidential_issue.title}']")
    end

    it 'redacts the cross project confidential issue even when the user has access' do
      other_project.add_developer(user)

      visit project_issue_path(project, issue)

      expect(page).not_to have_link(other_confidential_issue.to_reference(project))
      expect(page).not_to have_xpath("//a[@title='#{other_confidential_issue.title}']")
    end
  end
end
