# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views an open merge request', feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project, description: '# Description header')
  end

  context 'feature flags' do
    let_it_be(:project) { create(:project, :public, :repository) }

    it 'pushes content_editor_on_issues feature flag to frontend' do
      stub_feature_flags(content_editor_on_issues: true)

      visit merge_request_path(merge_request)

      expect(page).to have_pushed_frontend_feature_flags(contentEditorOnIssues: true)
    end
  end

  context 'when a merge request does not have repository' do
    let(:project) { create(:project, :public, :repository) }

    before do
      visit(merge_request_path(merge_request))
    end

    it 'renders both the title and the description' do
      node = find('.md h1 a#user-content-description-header')
      expect(node[:href]).to end_with('#description-header')

      # Work around a weird Capybara behavior where calling `parent` on a node
      # returns the whole document, not the node's actual parent element
      expect(find(:xpath, "#{node.path}/..").text).to eq(merge_request.description[2..])

      expect(page).to have_content(merge_request.title)
    end

    it 'has reviewers in sidebar' do
      expect(page).to have_css('.reviewer')
    end
  end

  context 'when a merge request has repository', :js do
    let(:project) { create(:project, :public, :repository) }

    context 'when rendering description preview' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)

        visit(edit_project_merge_request_path(project, merge_request))
      end

      it 'renders empty description preview' do
        fill_in(:merge_request_description, with: '')

        page.within('.js-vue-markdown-field') do
          click_button("Preview")

          expect(find('.js-vue-md-preview')).to have_content('Nothing to preview.')
        end
      end

      it 'renders description preview' do
        fill_in(:merge_request_description, with: ':+1: Nice')

        page.within('.js-vue-markdown-field') do
          click_button("Preview")

          expect(find('.js-vue-md-preview')).to have_css('gl-emoji')
        end

        expect(find('.js-vue-markdown-field')).to have_css('.js-md-preview-button')
        expect(find('#merge_request_description', visible: false)).not_to be_visible
      end
    end

    context 'when the branch is rebased on the target' do
      let(:merge_request) { create(:merge_request, :rebased, source_project: project, target_project: project) }

      before do
        project.add_maintainer(project.creator)
        sign_in(project.creator)

        visit(merge_request_path(merge_request))
      end

      it 'does not show diverged commits count' do
        expect(page).not_to have_content(/([0-9]+ commits? behind)/)
      end
    end

    context 'when the branch is diverged on the target' do
      let(:merge_request) { create(:merge_request, :diverged, source_project: project, target_project: project) }

      before do
        project.add_maintainer(project.creator)
        sign_in(project.creator)

        visit(merge_request_path(merge_request))
      end

      it 'shows diverged commits count', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408223' do
        expect(page).not_to have_content(/([0-9]+ commits? behind)/)
      end
    end

    context 'when the assignee\'s availability set' do
      before do
        merge_request.author.create_status(availability: 'busy')
        merge_request.assignees << merge_request.author

        visit(merge_request_path(merge_request))
      end

      it 'exposes the availability in the data-availability attribute' do
        assignees_data = find_all("input[name='merge_request[assignee_ids][]']", visible: false)

        expect(assignees_data.size).to eq(1)
        expect(assignees_data.first['data-availability']).to eq('busy')
      end
    end
  end

  context 'XSS source branch' do
    let(:project) { create(:project, :public, :repository) }
    let(:source_branch) { "&#39;&gt;&lt;iframe/srcdoc=&#39;&#39;&gt;&lt;/iframe&gt;" }

    before do
      stub_feature_flags(moved_mr_sidebar: false)

      project.repository.create_branch(source_branch, "master")

      mr = create(:merge_request, source_project: project, target_project: project, source_branch: source_branch)

      visit(merge_request_path(mr))
    end

    it 'encodes branch name' do
      expect(find("[data-testid='ref-name']")[:title]).to eq(source_branch)
    end
  end

  context 'when user preferred language has changed', :use_clean_rails_memory_store_fragment_caching do
    let(:project) { create(:project, :public, :repository) }
    let(:user) { create(:user) }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'renders edit button in preferred language' do
      visit(merge_request_path(merge_request))

      page.within('.detail-page-header-actions') do
        expect(page).to have_link('Edit')
      end

      user.update!(preferred_language: 'de')

      visit(merge_request_path(merge_request))

      page.within('.detail-page-header-actions') do
        expect(page).to have_link('Bearbeiten')
      end
    end
  end
end
