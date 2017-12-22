require 'spec_helper'

feature 'Merge Request closing issues message', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
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
    project.add_master(user)

    sign_in user

    visit project_merge_request_path(project, merge_request)
    wait_for_requests
  end

  context 'closing issues but not mentioning any other issue' do
    let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'mentioning issues but not closing them' do
    let(:merge_request_description) { "Description\n\nRefers to #{issue_1.to_reference} and #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Mentions #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'closing some issues in title and mentioning, but not closing, others' do
    let(:merge_request_title) { "closes #{issue_1.to_reference}\n\n refers to #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes #{issue_1.to_reference}")
      expect(page).to have_content("Mentions #{issue_2.to_reference}")
    end
  end

  context 'closing issues using title but not mentioning any other issue' do
    let(:merge_request_title) { "closing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'mentioning issues using title but not closing them' do
    let(:merge_request_title) { "Refers to #{issue_1.to_reference} and #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Mentions #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'closing some issues using title and mentioning, but not closing, others' do
    let(:merge_request_title) { "closes #{issue_1.to_reference}\n\n refers to #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes #{issue_1.to_reference}")
      expect(page).to have_content("Mentions #{issue_2.to_reference}")
    end
  end

  context 'approvals are enabled while closing issues', :js do
    before do
      project.add_developer(user)
    end

    let(:project) { create(:project, :public, :repository, approvals_before_merge: 1) }
    let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'displays closing issue message exactly one time' do
      wait_for_requests
      expect(page).to have_content("Closes #{issue_1.to_reference} and #{issue_2.to_reference}", count: 1)
    end
  end
end
