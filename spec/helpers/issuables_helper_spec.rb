# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesHelper, feature_category: :team_planning do
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
      expect(group_dropdown_label(non_existing_record_id, default)).to eq('default label')
    end
  end

  describe '#assignees_label' do
    let(:issuable) { build(:merge_request) }
    let(:assignee1) { build_stubbed(:user, name: 'Jane Doe') }
    let(:assignee2) { build_stubbed(:user, name: 'John Doe') }

    before do
      allow(issuable).to receive(:assignees).and_return(assignees)
    end

    context 'when multiple assignees exist' do
      let(:assignees) { [assignee1, assignee2] }

      it 'returns assignee label with assignee names' do
        expect(helper.assignees_label(issuable)).to eq("Assignees: Jane Doe and John Doe")
      end

      it 'returns assignee label only with include_value: false' do
        expect(helper.assignees_label(issuable, include_value: false)).to eq("Assignees")
      end

      context 'when the name contains a URL' do
        let(:assignees) { [build_stubbed(:user, name: 'www.gitlab.com')] }

        it 'returns sanitized name' do
          expect(helper.assignees_label(issuable)).to eq("Assignee: www_gitlab_com")
        end
      end
    end

    context 'when one assignee exists' do
      let(:assignees) { [assignee1] }

      it 'returns assignee label with no names' do
        expect(helper.assignees_label(issuable)).to eq("Assignee: Jane Doe")
      end

      it 'returns assignee label only with include_value: false' do
        expect(helper.assignees_label(issuable, include_value: false)).to eq("Assignee")
      end
    end

    context 'when no assignees exist' do
      let(:assignees) { [] }

      it 'returns assignee label with no names' do
        expect(helper.assignees_label(issuable)).to eq("Assignees: ")
      end

      it 'returns assignee label only with include_value: false' do
        expect(helper.assignees_label(issuable, include_value: false)).to eq("Assignees")
      end
    end
  end

  describe '#assigned_issuables_count', feature_category: :team_planning do
    context 'when issuable is issues' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, developers: user) }

      subject { helper.assigned_issuables_count(:issues) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when assigned issues count is over MAX_LIMIT_FOR_ASSIGNEED_ISSUES_COUNT' do
        before do
          stub_const('User::MAX_LIMIT_FOR_ASSIGNEED_ISSUES_COUNT', 2)
        end

        let_it_be(:issues) { create_list(:issue, 3, project: project, assignees: [user]) }

        it { is_expected.to eq 2 }
      end
    end
  end

  describe '#issuables_state_counter_text' do
    let_it_be(:user) { create(:user) }

    describe 'state text' do
      context 'when number of issuables can be generated' do
        before do
          allow(helper).to receive(:issuables_count_for_state).and_return(42)
        end

        it 'returns navigation with badges' do
          expect(helper.issuables_state_counter_text(:issues, :opened, true))
            .to eq('<span>Open</span> <span class="gl-badge badge badge-pill badge-muted gl-tab-counter-badge gl-hidden sm:gl-inline-flex"><span class="gl-badge-content">42</span></span>')
          expect(helper.issuables_state_counter_text(:issues, :closed, true))
            .to eq('<span>Closed</span> <span class="gl-badge badge badge-pill badge-muted gl-tab-counter-badge gl-hidden sm:gl-inline-flex"><span class="gl-badge-content">42</span></span>')
          expect(helper.issuables_state_counter_text(:merge_requests, :merged, true))
            .to eq('<span>Merged</span> <span class="gl-badge badge badge-pill badge-muted gl-tab-counter-badge gl-hidden sm:gl-inline-flex"><span class="gl-badge-content">42</span></span>')
          expect(helper.issuables_state_counter_text(:merge_requests, :all, true))
            .to eq('<span>All</span> <span class="gl-badge badge badge-pill badge-muted gl-tab-counter-badge gl-hidden sm:gl-inline-flex"><span class="gl-badge-content">42</span></span>')
        end
      end

      context 'when count cannot be generated' do
        before do
          allow(helper).to receive(:issuables_count_for_state).and_return(-1)
        end

        it 'returns navigation without badges' do
          expect(helper.issuables_state_counter_text(:issues, :opened, true))
            .to eq('<span>Open</span>')
          expect(helper.issuables_state_counter_text(:issues, :closed, true))
            .to eq('<span>Closed</span>')
          expect(helper.issuables_state_counter_text(:merge_requests, :merged, true))
            .to eq('<span>Merged</span>')
          expect(helper.issuables_state_counter_text(:merge_requests, :all, true))
            .to eq('<span>All</span>')
        end
      end

      context 'when count is over the threshold' do
        let_it_be(:group) { create(:group) }

        before do
          allow(helper).to receive(:issuables_count_for_state).and_return(1100)
          allow(helper).to receive(:parent).and_return(group)
          stub_const("Gitlab::IssuablesCountForState::THRESHOLD", 1000)
        end

        it 'returns truncated count' do
          expect(helper.issuables_state_counter_text(:issues, :opened, true))
            .to eq('<span>Open</span> <span class="gl-badge badge badge-pill badge-muted gl-tab-counter-badge gl-hidden sm:gl-inline-flex"><span class="gl-badge-content">1.1k</span></span>')
        end
      end
    end
  end

  describe '#issuable_reference' do
    let(:project_namespace) { build_stubbed(:project_namespace) }
    let(:project) { build_stubbed(:project, project_namespace: project_namespace) }

    context 'when show_full_reference truthy' do
      it 'display issuable full reference' do
        assign(:show_full_reference, true)
        issue = build_stubbed(:issue, project: project)

        expect(helper.issuable_reference(issue)).to eql(issue.to_reference(full: true))
      end
    end

    context 'when show_full_reference falsey' do
      context 'when @group present' do
        it 'display issuable reference to @group' do
          assign(:show_full_reference, nil)
          assign(:group, project.namespace)

          issue = build_stubbed(:issue, project: project)

          expect(helper.issuable_reference(issue)).to eql(issue.to_reference(project.namespace))
        end
      end

      context 'when @project present' do
        it 'display issuable reference to @project' do
          assign(:show_full_reference, nil)
          assign(:group, nil)
          assign(:project, project)

          issue = build_stubbed(:issue, project: project)

          expect(helper.issuable_reference(issue)).to eql(issue.to_reference(project))
        end
      end
    end
  end

  describe '#issuable_project_reference' do
    let(:project_namespace) { build_stubbed(:project_namespace) }
    let(:project) { build_stubbed(:project, project_namespace: project_namespace) }

    it 'display project name and simple reference with `#` to an issue' do
      issue = build_stubbed(:issue, project: project)

      expect(helper.issuable_project_reference(issue)).to eq("#{issue.project.full_name} ##{issue.iid}")
    end

    it 'display project name and simple reference with `!` to an MR' do
      merge_request = build_stubbed(:merge_request)

      expect(helper.issuable_project_reference(merge_request)).to eq("#{merge_request.project.full_name} !#{merge_request.iid}")
    end
  end

  describe '#issuable_initial_data' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
      stub_commonmark_sourcepos_disabled
    end

    context 'when issue' do
      it 'returns the correct data for an issue' do
        issue = create(:issue, author: user, description: 'issue text')
        @project = issue.project

        base_data = {
          endpoint: "/#{@project.full_path}/-/issues/#{issue.iid}",
          updateEndpoint: "/#{@project.full_path}/-/issues/#{issue.iid}.json",
          canUpdate: true,
          canDestroy: true,
          issuableRef: "##{issue.iid}",
          imported: issue.imported?,
          markdownPreviewPath: "/#{@project.full_path}/-/preview_markdown?target_id=#{issue.iid}&target_type=Issue",
          markdownDocsPath: '/help/user/markdown.md',
          lockVersion: issue.lock_version,
          issuableTemplateNamesPath: template_names_path(@project, issue),
          initialTitleHtml: issue.title,
          initialTitleText: issue.title,
          initialDescriptionHtml: '<p dir="auto">issue text</p>',
          initialDescriptionText: 'issue text',
          initialTaskCompletionStatus: { completed_count: 0, count: 0 }
        }

        issue_only_data = {
          canCreateIncident: true,
          fullPath: issue.project.full_path,
          iid: issue.iid,
          issuableId: issue.id,
          issueType: 'issue',
          isHidden: false,
          zoomMeetingUrl: nil
        }

        issue_header_data = {
          authorId: issue.author.id,
          authorName: issue.author.name,
          authorUsername: issue.author.username,
          authorWebUrl: url_for(user_path(issue.author)),
          createdAt: issue.created_at.to_time.iso8601,
          isFirstContribution: issue.first_contribution?,
          serviceDeskReplyTo: nil
        }

        work_items_data = {
          registerPath: '/users/sign_up?redirect_to_referer=yes',
          signInPath: '/users/sign_in?redirect_to_referer=yes'
        }

        path_data = {
          projectPath: @project.path,
          projectId: @project.id,
          projectNamespace: @project.namespace.path
        }

        expected = base_data.merge(issue_only_data, issue_header_data, work_items_data, path_data)

        expect(helper.issuable_initial_data(issue)).to include(expected)
      end
    end

    context 'for incident tab' do
      let(:incident) { create(:incident) }
      let(:params) do
        ActionController::Parameters.new({
          controller: "projects/incidents",
          action: "show",
          namespace_id: "foo",
          project_id: "bar",
          id: incident.iid,
          incident_tab: 'timeline'
        }).permit!
      end

      it 'includes incident attributes' do
        @project = incident.project
        allow(helper).to receive(:safe_params).and_return(params)

        expected_data = {
          issueType: 'incident',
          hasLinkedAlerts: false,
          canUpdateTimelineEvent: true,
          currentPath: "/foo/bar/-/issues/incident/#{incident.iid}/timeline",
          currentTab: 'timeline'
        }

        expect(helper.issuable_initial_data(incident)).to match(hash_including(expected_data))
      end
    end

    context 'when edited' do
      it 'contains edited metadata' do
        edited_issuable = create(:issue, author: user, description: 'issue text', last_edited_by: user, created_at: 3.days.ago, updated_at: 1.day.ago, last_edited_at: 2.days.ago)
        @project = edited_issuable.project

        expected = {
          updatedAt: edited_issuable.last_edited_at.to_time.iso8601,
          updatedBy: {
            name: user.name,
            path: user_path(user)
          }
        }

        expect(helper.issuable_initial_data(edited_issuable)).to include(expected)
      end

      context 'when updated by a deleted user' do
        let(:destroyed_user) { create(:user) }

        before do
          destroyed_user.destroy!
        end

        it 'returns "Ghost user" for updated by data' do
          edited_issuable = create(:issue, author: user, description: 'issue text', last_edited_by: destroyed_user, created_at: 3.days.ago, updated_at: 1.day.ago, last_edited_at: 2.days.ago)
          @project = edited_issuable.project

          expected = {
            updatedAt: edited_issuable.last_edited_at.to_time.iso8601,
            updatedBy: {
              name: Users::Internal.ghost.name,
              path: user_path(Users::Internal.ghost)
            }
          }

          expect(helper.issuable_initial_data(edited_issuable.reload)).to include(expected)
        end
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

    describe '#duplicatedToIssueUrl' do
      let(:issue) { create(:issue, author: user) }

      before do
        assign(:project, issue.project)
      end

      context 'when issue is duplicated' do
        before do
          allow(issue).to receive(:duplicated?).and_return(true)
          allow(issue).to receive(:duplicated_to).and_return(issue)
        end

        it 'returns url' do
          expect(helper.issuable_initial_data(issue)[:duplicatedToIssueUrl]).to be_truthy
        end
      end

      context 'when issue is not duplicated' do
        before do
          allow(issue).to receive(:duplicated?).and_return(false)
        end

        it 'returns nil' do
          expect(helper.issuable_initial_data(issue)[:duplicatedToIssueUrl]).to be_nil
        end
      end
    end

    describe '#movedToIssueUrl' do
      let(:issue) { create(:issue, author: user) }

      before do
        assign(:project, issue.project)
      end

      context 'when issue is moved' do
        before do
          allow(issue).to receive(:moved?).and_return(true)
          allow(issue).to receive(:moved_to).and_return(issue)
        end

        it 'returns url' do
          expect(helper.issuable_initial_data(issue)[:movedToIssueUrl]).to be_truthy
        end
      end

      context 'when issue is not moved' do
        before do
          allow(issue).to receive(:moved?).and_return(false)
        end

        it 'returns nil' do
          expect(helper.issuable_initial_data(issue)[:movedToIssueUrl]).to be_nil
        end
      end
    end
  end

  describe '#issuable_squash_option?' do
    using RSpec::Parameterized::TableSyntax

    where(:issuable_persisted, :squash, :squash_enabled_by_default, :expectation) do
      true  | true  | true  | true
      true  | false | true  | false
      false | false | false | false
      false | false | true  | true
      false | true  | false | false
      false | true  | true  | true
    end

    with_them do
      it 'returns the correct value' do
        project = double(
          squash_enabled_by_default?: squash_enabled_by_default
        )
        issuable = double(persisted?: issuable_persisted, squash: squash)

        expect(helper.issuable_squash_option?(issuable, project)).to eq(expectation)
      end
    end
  end

  describe '#issuable_type_selector_data' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project) }

    where(:issuable_type, :issuable_display_type, :is_issue_allowed, :is_incident_allowed) do
      :issue         | 'issue'    | true  | false
      :incident      | 'incident' | false | true
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      before do
        allow(helper).to receive(:create_issue_type_allowed?).with(project, :issue).and_return(is_issue_allowed)
        allow(helper).to receive(:create_issue_type_allowed?).with(project, :incident).and_return(is_incident_allowed)
        assign(:project, project)
      end

      it 'returns the correct data for the issuable type selector' do
        expected_data = {
          selected_type: issuable_display_type,
          is_issue_allowed: is_issue_allowed.to_s,
          is_incident_allowed: is_incident_allowed.to_s,
          issue_path: new_project_issue_path(project),
          incident_path: new_project_issue_path(project, { issuable_template: 'incident', issue: { issue_type: 'incident' } })
        }

        expect(helper.issuable_type_selector_data(issuable)).to match(expected_data)
      end
    end
  end

  describe '#issuable_label_selector_data' do
    let_it_be(:project) { create(:project, :repository) }

    context 'with a new issuable' do
      let_it_be(:issuable) { build(:issue, project: project) }

      it 'returns the expected data' do
        expect(helper.issuable_label_selector_data(project, issuable)).to match({
          field_name: "#{issuable.class.model_name.param_key}[label_ids][]",
          full_path: project.full_path,
          initial_labels: '[]',
          issuable_type: issuable.issuable_type,
          labels_filter_base_path: project_issues_path(project),
          labels_manage_path: project_labels_path(project),
          supports_lock_on_merge: issuable.supports_lock_on_merge?.to_s
        })
      end
    end

    context 'with an existing issuable' do
      let_it_be(:label) { create(:label, name: 'Bug') }
      let_it_be(:label2) { create(:label, name: 'Community contribution') }
      let_it_be(:issuable) do
        create(:merge_request, source_project: project, target_project: project, labels: [label, label2])
      end

      it 'returns the expected data' do
        initial_labels = [
          {
            __typename: "Label",
            id: label.id,
            title: label.title,
            description: label.description,
            color: label.color,
            text_color: label.text_color,
            lock_on_merge: label.lock_on_merge
          },
          {
            __typename: "Label",
            id: label2.id,
            title: label2.title,
            description: label2.description,
            color: label2.color,
            text_color: label2.text_color,
            lock_on_merge: label.lock_on_merge
          }
        ]

        expect(helper.issuable_label_selector_data(project, issuable)).to match({
          field_name: "#{issuable.class.model_name.param_key}[label_ids][]",
          full_path: project.full_path,
          initial_labels: initial_labels.to_json,
          issuable_type: issuable.issuable_type,
          labels_filter_base_path: project_merge_requests_path(project),
          labels_manage_path: project_labels_path(project),
          supports_lock_on_merge: issuable.supports_lock_on_merge?.to_s
        })
      end
    end
  end
end
