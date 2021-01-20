# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'viewing an issue', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:note) { create(:note_on_issue, project: project, noteable: issue) }
  let_it_be(:participants) { create_list(:issue_email_participant, 4, issue: issue) }

  before do
    sign_in(user)
    visit project_issue_path(project, issue)
  end

  shared_examples 'email participants warning' do |selector|
    it 'shows the correct message' do
      expect(find(selector)).to have_content(", and 1 more will be notified of your comment")
    end
  end

  context 'for a new note' do
    it_behaves_like 'email participants warning', '.new-note'
  end

  context 'for a reply form' do
    before do
      find('.js-reply-button').click
    end

    it_behaves_like 'email participants warning', '.note-edit-form'
  end
end
