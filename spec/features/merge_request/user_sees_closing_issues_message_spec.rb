# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees closing issues message', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:issue_1) { create(:issue, project: project) }
  let(:issue_2) { create(:issue, project: project) }
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
    project.add_maintainer(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
    wait_for_requests
  end

  context 'closing issues but not mentioning any other issue' do
    let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes issues #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'mentioning issues but not closing them' do
    let(:merge_request_description) { "Description\n\nRefers to #{issue_1.to_reference} and #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Mentions issues #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'closing some issues in title and mentioning, but not closing, others' do
    let(:merge_request_title) { "closes #{issue_1.to_reference}\n\n refers to #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes issue #{issue_1.to_reference}")
      expect(page).to have_content("Mentions issue #{issue_2.to_reference}")
    end
  end

  context 'closing issues using title but not mentioning any other issue' do
    let(:merge_request_title) { "closing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes issues #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'mentioning issues using title but not closing them' do
    let(:merge_request_title) { "Refers to #{issue_1.to_reference} and #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Mentions issues #{issue_1.to_reference} and #{issue_2.to_reference}")
    end
  end

  context 'closing some issues using title and mentioning, but not closing, others' do
    let(:merge_request_title) { "closes #{issue_1.to_reference}\n\n refers to #{issue_2.to_reference}" }

    it 'does not display closing issue message' do
      expect(page).to have_content("Closes issue #{issue_1.to_reference}")
      expect(page).to have_content("Mentions issue #{issue_2.to_reference}")
    end
  end
end
