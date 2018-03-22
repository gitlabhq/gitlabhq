require 'spec_helper'

describe 'viewing an issue with cross project references' do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Routing.url_helpers

  let(:user) { create(:user) }
  let(:other_project) do
    create(:project, :public,
          external_authorization_classification_label: 'other_label')
  end
  let(:other_issue) do
    create(:issue, :closed,
           title: 'I am in another project',
           project: other_project)
  end
  let(:other_confidential_issue) do
    create(:issue, :confidential, :closed,
           title: 'I am in another project and confidential',
           project: other_project)
  end
  let(:description_referencing_other_issue) do
    "Referencing: #{other_issue.to_reference(project)}, and "\
    "a confidential issue #{confidential_issue.to_reference}"\
    "a cross project confidential issue #{other_confidential_issue.to_reference(project)}"
  end
  let(:project) { create(:project) }
  let(:issue) do
    create(:issue,
           project: project,
           description: description_referencing_other_issue )
  end
  let(:confidential_issue) do
    create(:issue, :confidential, :closed,
           title: "I am in the same project and confidential",
           project: project)
  end

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'shows all information related to the cross project reference' do
    visit project_issue_path(project, issue)

    expect(page).to have_link("#{other_issue.to_reference(project)} (#{other_issue.state})")
    expect(page).to have_xpath("//a[@title='#{other_issue.title}']")
  end

  it 'shows a link to the confidential issue in the same project' do
    visit project_issue_path(project, issue)

    expect(page).to have_link("#{confidential_issue.to_reference(project)} (#{confidential_issue.state})")
    expect(page).to have_xpath("//a[@title='#{confidential_issue.title}']")
  end

  it 'does not show the link to a cross project confidential issue when the user does not have access' do
    visit project_issue_path(project, issue)

    expect(page).not_to have_link("#{other_confidential_issue.to_reference(project)} (#{other_confidential_issue.state})")
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
      expect(EE::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'default_label').at_least(1).and_return(true)

      visit project_issue_path(project, issue)
    end

    it 'shows only the link to the cross project reference' do
      visit project_issue_path(project, issue)

      expect(page).to have_link("#{other_issue.to_reference(project)}")
      expect(page).not_to have_content("#{other_issue.to_reference(project)} (#{other_issue.state})")
      expect(page).not_to have_xpath("//a[@title='#{other_issue.title}']")
    end

    it 'does not link a cross project confidential issue if the user does not have access' do
      visit project_issue_path(project, issue)

      expect(page).not_to have_link("#{other_confidential_issue.to_reference(project)}")
      expect(page).not_to have_xpath("//a[@title='#{other_confidential_issue.title}']")
    end

    it 'links a cross project confidential issue without exposing information when the user has access' do
      other_project.add_developer(user)

      visit project_issue_path(project, issue)

      expect(page).to have_link("#{other_confidential_issue.to_reference(project)}")
      expect(page).not_to have_xpath("//a[@title='#{other_confidential_issue.title}']")
    end

    it 'shows a link to the confidential issue in the same project' do
      visit project_issue_path(project, issue)

      expect(page).to have_link("#{confidential_issue.to_reference(project)} (#{confidential_issue.state})")
      expect(page).to have_xpath("//a[@title='#{confidential_issue.title}']")
    end
  end
end
