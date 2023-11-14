# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User opens checkout branch modal', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
  end

  describe 'for fork' do
    let(:author) { create(:user) }
    let(:source_project) { fork_project(project, author, repository: true) }

    let(:merge_request) do
      create(
        :merge_request,
        source_project: source_project,
        target_project: project,
        source_branch: 'fix',
        target_branch: 'master',
        author: author,
        allow_collaboration: true
      )
    end

    it 'shows instructions' do
      visit project_merge_request_path(project, merge_request)

      page.within 'main' do
        click_button 'Code'
        click_button 'Check out branch'
      end

      expect(page).to have_content(source_project.http_url_to_repo)
    end
  end
end
