# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'iframe rendering', :js, feature_category: :markdown do
  let_it_be(:project) { create(:project, :public, :repository) }

  # No registration of .example domains is possible:
  # https://en.wikipedia.org/wiki/.example
  let(:markdown) do
    <<~MARKDOWN
    ![](https://iframe.example/some-video)
    MARKDOWN
  end

  let(:expected_selector) do
    'iframe[src="https://iframe.example/some-video"][sandbox]'
  end

  let(:untouched_selector) do
    'img[data-src="https://iframe.example/some-video"],
     img[src="https://iframe.example/some-video"]'
  end

  context 'when feature is enabled and configured' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: true)
      stub_application_setting(iframe_rendering_enabled: true, iframe_rendering_allowlist: ['iframe.example'])
    end

    context 'in an issue' do
      let(:issue) { create(:issue, project: project, description: markdown) }

      it 'includes iframe embed correctly' do
        visit project_issue_path(project, issue)
        wait_for_requests

        expect(page).to have_css(expected_selector)
      end
    end

    context 'in a merge request' do
      let(:merge_request) { create(:merge_request_with_diffs, source_project: project, description: markdown) }

      it 'renders diffs and includes iframe correctly' do
        visit(diffs_project_merge_request_path(project, merge_request))

        wait_for_requests

        page.within('.tab-content') do
          expect(page).to have_selector('.diffs')
        end

        visit(project_merge_request_path(project, merge_request))

        wait_for_requests

        page.within('.merge-request') do
          expect(page).to have_css(expected_selector)
        end
      end
    end

    context 'in a project milestone' do
      let(:milestone) { create(:project_milestone, project: project, description: markdown) }

      it 'includes iframe correctly' do
        visit(project_milestone_path(project, milestone))

        wait_for_requests

        expect(page).to have_css(expected_selector)
      end
    end

    context 'in a project home page' do
      let!(:wiki) { create(:project_wiki, project: project) }
      let!(:wiki_page) { create(:wiki_page, wiki: wiki, title: 'home', content: markdown) }

      before do
        project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)
      end

      it 'includes iframe correctly' do
        visit(project_path(project))

        wait_for_all_requests

        page.within '.js-wiki-content' do
          expect(page).to have_css(expected_selector)
        end
      end
    end

    context 'in a group milestone' do
      let(:group_milestone) { create(:group_milestone, description: markdown) }

      it 'includes iframe correctly' do
        visit(group_milestone_path(group_milestone.group, group_milestone))

        wait_for_requests

        expect(page).to have_css(expected_selector)
      end
    end
  end

  context 'when feature is enabled but not configured' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: true)
      stub_application_setting(iframe_rendering_enabled: false)
    end

    context 'in an issue' do
      let(:issue) { create(:issue, project: project, description: markdown) }

      it 'no iframe is added, the image tag is left untouched' do
        visit project_issue_path(project, issue)
        wait_for_requests

        expect(page).not_to have_css(expected_selector)
        # The image may be considered invisible because of the invalid target;
        # the main thing is it's there, and it's not an iframe.
        expect(page).to have_css(untouched_selector, visible: :all)
      end
    end
  end
end
