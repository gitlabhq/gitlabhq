# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Observability rendering', :js do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:observable_url) { "https://observe.gitlab.com/" }

  let_it_be(:expected) do
    %(<iframe src="#{observable_url}?theme=light&amp;kiosk" frameborder="0")
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when embedding in an issue' do
    let(:issue) do
      create(:issue, project: project, description: observable_url)
    end

    before do
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'renders iframe in description' do
      page.within('.description') do
        expect(page.html).to include(expected)
      end
    end

    it 'renders iframe in comment' do
      expect(page).not_to have_css('.note-text')

      page.within('.js-main-target-form') do
        fill_in('note[note]', with: observable_url)
        click_button('Comment')
      end

      wait_for_requests

      page.within('.note-text') do
        expect(page.html).to include(expected)
      end
    end
  end

  context 'when embedding in an MR' do
    let(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, description: observable_url)
    end

    before do
      visit merge_request_path(merge_request)
      wait_for_requests
    end

    it 'renders iframe in description' do
      page.within('.description') do
        expect(page.html).to include(expected)
      end
    end

    it 'renders iframe in comment' do
      expect(page).not_to have_css('.note-text')

      page.within('.js-main-target-form') do
        fill_in('note[note]', with: observable_url)
        click_button('Comment')
      end

      wait_for_requests

      page.within('.note-text') do
        expect(page.html).to include(expected)
      end
    end
  end
end
