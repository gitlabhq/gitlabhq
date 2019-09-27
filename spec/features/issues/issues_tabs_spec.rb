# frozen_string_literal: true

require 'spec_helper'

describe 'Issue page tabs', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, author: user, assignees: [user], project: project) }

  describe 'discussions tab counter' do
    before do
      stub_licensed_features(design_management: true)
      stub_feature_flags(design_management_flag: true)
      allow(Ability).to receive(:allowed?) { true }
    end

    subject do
      sign_in(user)

      visit project_issue_path(project, issue)

      wait_for_requests

      find('#discussion')
    end

    context 'new issue' do
      it 'displays count of 0' do
        is_expected.to have_content('Discussion 0')
      end
    end

    context 'issue with 2 system notes and 1 discussion' do
      let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: project, note: "This is good") }

      before do
        create(:system_note, noteable: issue, project: project, author: user, note: 'description updated')
        create(:system_note, noteable: issue, project: project, author: user, note: 'description updated')
      end

      it 'displays count of 1' do
        is_expected.to have_content('Discussion 1')
      end

      context 'with 1 reply' do
        before do
          create(:note, noteable: issue, in_reply_to: discussion, discussion_id: discussion.discussion_id, note: 'I also think this is good')
        end

        it 'displays count of 2' do
          is_expected.to have_content('Discussion 2')
        end
      end
    end
  end
end
