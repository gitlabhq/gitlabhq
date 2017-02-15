require 'spec_helper'

feature 'Merge Request closing issues message', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue_1) { create(:issue, project: project)}
  let(:issue_2) { create(:issue, project: project)}
  let(:merge_request) do
    create(
      :merge_request,
      :simple,
      source_project: project,
      description: merge_request_description,
      title: merge_request_title
    )
  end
  let(:merge_request_description) { 'Merge Request Description' }
  let(:merge_request_title) { 'Merge Request Title' }

  before do
    project.team << [user, :master]

    login_as user

    visit namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'not closing or mentioning any issue' do
    it 'does not display closing issue message' do
      expect(page).not_to have_css('.mr-widget-footer')
    end
  end

  context 'closing issues but not mentioning any other issue' do
    let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Accepting this merge request will close issues #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'mentioning issues but not closing them' do
    let(:merge_request_description) { "Description\n\nRefers to #{issue_1.to_reference} and #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Issues #{issue_1.to_reference} and #{issue_2.to_reference} are mentioned but will not be closed.")
    end
  end

  context 'closing some issues in title and mentioning, but not closing, others' do
    let(:merge_request_title) { "closes #{issue_1.to_reference}\n\n refers to #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Accepting this merge request will close issue #{issue_1.to_reference}. Issue #{issue_2.to_reference} is mentioned but will not be closed.")
    end
  end

  context 'closing issues using title but not mentioning any other issue' do
    let(:merge_request_title) { "closing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Accepting this merge request will close issues #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'mentioning issues using title but not closing them' do
    let(:merge_request_title) { "Refers to #{issue_1.to_reference} and #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Issues #{issue_1.to_reference} and #{issue_2.to_reference} are mentioned but will not be closed.")
    end
  end

  context 'closing some issues using title and mentioning, but not closing, others' do
    let(:merge_request_title) { "closes #{issue_1.to_reference}\n\n refers to #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Accepting this merge request will close issue #{issue_1.to_reference}. Issue #{issue_2.to_reference} is mentioned but will not be closed.")
    end
  end
end
