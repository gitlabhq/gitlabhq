# frozen_string_literal: true

require 'spec_helper'

describe NotificationSetting do
  describe '.email_events' do
    subject { described_class.email_events(target) }

    context 'group' do
      let(:target) { build_stubbed(:group) }

      it 'appends EE specific events' do
        expect(subject).to eq(
          [
            :new_note,
            :new_issue,
            :reopen_issue,
            :close_issue,
            :reassign_issue,
            :issue_due,
            :new_merge_request,
            :push_to_merge_request,
            :reopen_merge_request,
            :close_merge_request,
            :reassign_merge_request,
            :merge_merge_request,
            :failed_pipeline,
            :success_pipeline,
            :new_epic
          ]
        )
      end
    end

    context 'project' do
      let(:target) { build_stubbed(:project) }

      it 'returns CE list' do
        expect(subject).to eq(
          [
            :new_note,
            :new_issue,
            :reopen_issue,
            :close_issue,
            :reassign_issue,
            :issue_due,
            :new_merge_request,
            :push_to_merge_request,
            :reopen_merge_request,
            :close_merge_request,
            :reassign_merge_request,
            :merge_merge_request,
            :failed_pipeline,
            :success_pipeline
          ]
        )
      end
    end
  end
end
