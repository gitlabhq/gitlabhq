# frozen_string_literal: true

require 'spec_helper'

describe IssuablesHelper do
  let(:label)  { build_stubbed(:label) }
  let(:label2) { build_stubbed(:label) }

  describe '#users_dropdown_label' do
    let(:user) { build_stubbed(:user) }
    let(:user2) { build_stubbed(:user) }

    it 'returns unassigned' do
      expect(users_dropdown_label([])).to eq('Unassigned')
    end

    it 'returns selected user\'s name' do
      expect(users_dropdown_label([user])).to eq(user.name)
    end

    it 'returns selected user\'s name and counter' do
      expect(users_dropdown_label([user, user2])).to eq("#{user.name} + 1 more")
    end
  end

  describe '#group_dropdown_label' do
    let(:group) { create(:group) }
    let(:default) { 'default label' }

    it 'returns default group label when group_id is nil' do
      expect(group_dropdown_label(nil, default)).to eq('default label')
    end

    it 'returns "any group" when group_id is 0' do
      expect(group_dropdown_label('0', default)).to eq('Any group')
    end

    it 'returns group full path when a group was found for the provided id' do
      expect(group_dropdown_label(group.id, default)).to eq(group.full_name)
    end

    it 'returns default label when a group was not found for the provided id' do
      expect(group_dropdown_label(9999, default)).to eq('default label')
    end
  end

  describe '#issuable_labels_tooltip' do
    let(:label_entity) { LabelEntity.represent(label).as_json }
    let(:label2_entity) { LabelEntity.represent(label2).as_json }

    it 'returns label text with no labels' do
      expect(issuable_labels_tooltip([])).to eq(_('Labels'))
    end

    it 'returns label text with labels within max limit' do
      expect(issuable_labels_tooltip([label_entity])).to eq(label[:title])
    end

    it 'returns label text with labels exceeding max limit' do
      expect(issuable_labels_tooltip([label_entity, label2_entity], limit: 1)).to eq("#{label[:title]}, and 1 more")
    end
  end

  describe '#issuables_state_counter_text' do
    let(:user) { create(:user) }

    describe 'state text' do
      before do
        allow(helper).to receive(:issuables_count_for_state).and_return(42)
      end

      it 'returns "Open" when state is :opened' do
        expect(helper.issuables_state_counter_text(:issues, :opened, true))
          .to eq('<span>Open</span> <span class="badge badge-pill">42</span>')
      end

      it 'returns "Closed" when state is :closed' do
        expect(helper.issuables_state_counter_text(:issues, :closed, true))
          .to eq('<span>Closed</span> <span class="badge badge-pill">42</span>')
      end

      it 'returns "Merged" when state is :merged' do
        expect(helper.issuables_state_counter_text(:merge_requests, :merged, true))
          .to eq('<span>Merged</span> <span class="badge badge-pill">42</span>')
      end

      it 'returns "All" when state is :all' do
        expect(helper.issuables_state_counter_text(:merge_requests, :all, true))
          .to eq('<span>All</span> <span class="badge badge-pill">42</span>')
      end
    end
  end

  describe '#issuable_reference' do
    context 'when show_full_reference truthy' do
      it 'display issuable full reference' do
        assign(:show_full_reference, true)
        issue = build_stubbed(:issue)

        expect(helper.issuable_reference(issue)).to eql(issue.to_reference(full: true))
      end
    end

    context 'when show_full_reference falsey' do
      context 'when @group present' do
        it 'display issuable reference to @group' do
          project = build_stubbed(:project)

          assign(:show_full_reference, nil)
          assign(:group, project.namespace)

          issue = build_stubbed(:issue)

          expect(helper.issuable_reference(issue)).to eql(issue.to_reference(project.namespace))
        end
      end

      context 'when @project present' do
        it 'display issuable reference to @project' do
          project = build_stubbed(:project)

          assign(:show_full_reference, nil)
          assign(:group, nil)
          assign(:project, project)

          issue = build_stubbed(:issue)

          expect(helper.issuable_reference(issue)).to eql(issue.to_reference(project))
        end
      end
    end
  end

  describe '#updated_at_by' do
    let(:user) { create(:user) }
    let(:unedited_issuable) { create(:issue) }
    let(:edited_issuable) { create(:issue, last_edited_by: user, created_at: 3.days.ago, updated_at: 1.day.ago, last_edited_at: 2.days.ago) }
    let(:edited_updated_at_by) do
      {
        updatedAt: edited_issuable.last_edited_at.to_time.iso8601,
        updatedBy: {
          name: user.name,
          path: user_path(user)
        }
      }
    end

    it { expect(helper.updated_at_by(unedited_issuable)).to eq({}) }
    it { expect(helper.updated_at_by(edited_issuable)).to eq(edited_updated_at_by) }

    context 'when updated by a deleted user' do
      let(:edited_updated_at_by) do
        {
          updatedAt: edited_issuable.last_edited_at.to_time.iso8601,
          updatedBy: {
            name: User.ghost.name,
            path: user_path(User.ghost)
          }
        }
      end

      before do
        user.destroy
      end

      it 'returns "Ghost user" as edited_by' do
        expect(helper.updated_at_by(edited_issuable.reload)).to eq(edited_updated_at_by)
      end
    end
  end

  describe '#issuable_initial_data' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
      stub_commonmark_sourcepos_disabled
    end

    it 'returns the correct data for an issue' do
      issue = create(:issue, author: user, description: 'issue text')
      @project = issue.project

      expected_data = {
        endpoint: "/#{@project.full_path}/issues/#{issue.iid}",
        updateEndpoint: "/#{@project.full_path}/issues/#{issue.iid}.json",
        canUpdate: true,
        canDestroy: true,
        issuableRef: "##{issue.iid}",
        markdownPreviewPath: "/#{@project.full_path}/preview_markdown",
        markdownDocsPath: '/help/user/markdown',
        lockVersion: issue.lock_version,
        projectPath: @project.path,
        projectNamespace: @project.namespace.path,
        initialTitleHtml: issue.title,
        initialTitleText: issue.title,
        initialDescriptionHtml: '<p dir="auto">issue text</p>',
        initialDescriptionText: 'issue text',
        initialTaskStatus: '0 of 0 tasks completed'
      }
      expect(helper.issuable_initial_data(issue)).to match(hash_including(expected_data))
    end

    describe '#sentryIssueIdentifier' do
      let(:issue) { create(:issue, author: user) }

      before do
        assign(:project, issue.project)
      end

      it 'sets sentryIssueIdentifier to nil with no sentry issue ' do
        expect(helper.issuable_initial_data(issue)[:sentryIssueIdentifier])
          .to be_nil
      end

      it 'sets sentryIssueIdentifier to sentry_issue_identifier' do
        sentry_issue = create(:sentry_issue, issue: issue)

        expect(helper.issuable_initial_data(issue)[:sentryIssueIdentifier])
          .to eq(sentry_issue.sentry_issue_identifier)
      end
    end

    describe '#zoomMeetingUrl in issue' do
      let(:issue) { create(:issue, author: user) }

      before do
        assign(:project, issue.project)
      end

      shared_examples 'sets zoomMeetingUrl to nil' do
        specify do
          expect(helper.issuable_initial_data(issue)[:zoomMeetingUrl])
            .to be_nil
        end
      end

      context 'with no "added" zoom mettings' do
        it_behaves_like 'sets zoomMeetingUrl to nil'

        context 'with multiple removed meetings' do
          before do
            create(:zoom_meeting, issue: issue, issue_status: :removed)
            create(:zoom_meeting, issue: issue, issue_status: :removed)
          end

          it_behaves_like 'sets zoomMeetingUrl to nil'
        end
      end

      context 'with "added" zoom meeting' do
        before do
          create(:zoom_meeting, issue: issue)
        end

        shared_examples 'sets zoomMeetingUrl to canonical meeting url' do
          specify do
            expect(helper.issuable_initial_data(issue))
              .to include(zoomMeetingUrl: 'https://zoom.us/j/123456789')
          end
        end

        it_behaves_like 'sets zoomMeetingUrl to canonical meeting url'

        context 'with muliple "removed" zoom meetings' do
          before do
            create(:zoom_meeting, issue: issue, issue_status: :removed)
            create(:zoom_meeting, issue: issue, issue_status: :removed)
          end

          it_behaves_like 'sets zoomMeetingUrl to canonical meeting url'
        end
      end
    end
  end

  describe '#assignee_sidebar_data' do
    let(:user) { create(:user) }
    let(:merge_request) { nil }
    subject { helper.assignee_sidebar_data(user, merge_request: merge_request) }

    it 'returns hash of assignee data' do
      is_expected.to eql({
        avatar_url: user.avatar_url,
        name: user.name,
        username: user.username
      })
    end

    context 'with merge_request' do
      let(:merge_request) { build_stubbed(:merge_request) }

      where(can_merge: [true, false])

      with_them do
        before do
          allow(merge_request).to receive(:can_be_merged_by?).and_return(can_merge)
        end

        it { is_expected.to include({ can_merge: can_merge })}
      end
    end
  end
end
