# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue state', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  shared_examples 'issue closed' do |selector|
    it 'can close an issue' do
      wait_for_requests

      expect(find('.status-box')).to have_content 'Open'

      within selector do
        click_button 'Close issue'
        wait_for_requests
      end

      expect(find('.status-box')).to have_content 'Closed'
    end
  end

  shared_examples 'issue reopened' do |selector|
    it 'can reopen an issue' do
      wait_for_requests

      expect(find('.status-box')).to have_content 'Closed'

      within selector do
        click_button 'Reopen issue'
        wait_for_requests
      end

      expect(find('.status-box')).to have_content 'Open'
    end
  end

  describe 'when open', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/297348' do
    let(:open_issue) { create(:issue, project: project) }

    it_behaves_like 'page with comment and close button', 'Close issue' do
      def setup
        visit project_issue_path(project, open_issue)
      end
    end

    context 'when clicking the top `Close issue` button', :aggregate_failures do
      before do
        visit project_issue_path(project, open_issue)
      end

      it_behaves_like 'issue closed', '.detail-page-header'
    end

    context 'when clicking the bottom `Close issue` button', :aggregate_failures do
      before do
        stub_feature_flags(remove_comment_close_reopen: false)
        visit project_issue_path(project, open_issue)
      end

      it_behaves_like 'issue closed', '.timeline-content-form'
    end
  end

  describe 'when closed', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/297201' do
    let(:closed_issue) { create(:issue, project: project, state: 'closed') }

    it_behaves_like 'page with comment and close button', 'Reopen issue' do
      def setup
        visit project_issue_path(project, closed_issue)
      end
    end

    context 'when clicking the top `Reopen issue` button', :aggregate_failures do
      before do
        visit project_issue_path(project, closed_issue)
      end

      it_behaves_like 'issue reopened', '.detail-page-header'
    end

    context 'when clicking the bottom `Reopen issue` button', :aggregate_failures do
      before do
        stub_feature_flags(remove_comment_close_reopen: false)
        visit project_issue_path(project, closed_issue)
      end

      it_behaves_like 'issue reopened', '.timeline-content-form'
    end
  end
end
