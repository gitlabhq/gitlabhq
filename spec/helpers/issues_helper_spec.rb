# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesHelper, feature_category: :team_planning do
  include Features::MergeRequestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }

  describe '#award_user_list' do
    it 'returns a comma-separated list of the first X users' do
      user = build_stubbed(:user, name: 'Joe')
      awards = Array.new(3, build_stubbed(:award_emoji, user: user))

      expect(award_user_list(awards, nil, limit: 3))
        .to eq('Joe, Joe, and Joe')
    end

    it "displays the current user's name as 'You'" do
      user = build_stubbed(:user, name: 'Joe')
      award = build_stubbed(:award_emoji, user: user)

      expect(award_user_list([award], user)).to eq('You')
      expect(award_user_list([award], nil)).to eq 'Joe'
    end

    it 'truncates lists' do
      user = build_stubbed(:user, name: 'Jane')
      awards = Array.new(5, build_stubbed(:award_emoji, user: user))

      expect(award_user_list(awards, nil, limit: 3))
        .to eq('Jane, Jane, Jane, and 2 more.')
    end

    it 'displays the current user in front of other users' do
      current_user = build_stubbed(:user)
      my_award = build_stubbed(:award_emoji, user: current_user)
      award = build_stubbed(:award_emoji, user: build_stubbed(:user, name: 'Jane'))
      awards = Array.new(5, award).push(my_award)

      expect(award_user_list(awards, current_user, limit: 2))
        .to eq('You, Jane, and 4 more.')
    end
  end

  describe '#award_state_class' do
    let_it_be(:upvote) { create(:award_emoji) }
    let(:awardable) { upvote.awardable }

    before_all do
      upvote.awardable.project.add_guest(upvote.user)
    end

    before do
      allow(helper).to receive(:can?) do |*args|
        Ability.allowed?(*args)
      end
    end

    it 'returns disabled string for unauthenticated user' do
      expect(helper.award_state_class(awardable, AwardEmoji.all, nil)).to eq('disabled')
    end

    it 'returns disabled for a user that does not have access to the awardable' do
      expect(helper.award_state_class(awardable, AwardEmoji.all, build(:user))).to eq('disabled')
    end

    it 'returns selected class for author' do
      expect(helper.award_state_class(awardable, AwardEmoji.all, upvote.user)).to eq('selected')
    end

    it 'is blank for a user that has access to the awardable' do
      user = build(:user)
      expect(helper).to receive(:can?).with(user, :award_emoji, awardable).and_return(true)

      expect(helper.award_state_class(awardable, AwardEmoji.all, user)).to be_blank
    end
  end

  describe 'awards_sort' do
    it 'sorts a hash so thumbsup and thumbsdown are always on top' do
      data = { AwardEmoji::THUMBS_DOWN => 'some value', 'lifter' => 'some value', AwardEmoji::THUMBS_UP => 'some value' }
      expect(awards_sort(data).keys).to eq(%W[#{AwardEmoji::THUMBS_UP} #{AwardEmoji::THUMBS_DOWN} lifter])
    end
  end

  describe '#link_to_discussions_to_resolve' do
    describe 'passing only a merge request' do
      let(:merge_request) { create(:merge_request) }

      it 'links just the merge request' do
        expected_path = project_merge_request_path(merge_request.project, merge_request)

        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(expected_path)
      end

      it 'contains the reference to the merge request' do
        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(merge_request.to_reference)
      end
    end

    describe 'when passing a discussion' do
      let(:diff_note) { create(:diff_note_on_merge_request) }
      let(:merge_request) { diff_note.noteable }
      let(:discussion) { diff_note.to_discussion }

      it 'links to the merge request with first note if a single discussion was passed' do
        expected_path = Gitlab::UrlBuilder.build(diff_note)

        expect(link_to_discussions_to_resolve(merge_request, discussion)).to include(expected_path)
      end

      it 'contains both the reference to the merge request and a mention of the discussion' do
        expect(link_to_discussions_to_resolve(merge_request, discussion)).to include("#{merge_request.to_reference} (discussion #{diff_note.id})")
      end
    end
  end

  describe '#show_new_issue_link?' do
    before do
      allow(helper).to receive(:current_user)
    end

    it 'is false when no project there is no project' do
      expect(helper.show_new_issue_link?(nil)).to be_falsey
    end

    it 'is true when there is a project and no logged in user' do
      expect(helper.show_new_issue_link?(build(:project))).to be_truthy
    end

    it 'is true when the current user does not have access to the project' do
      project = build(:project)
      allow(helper).to receive(:current_user).and_return(project.owner)

      expect(helper).to receive(:can?).with(project.owner, :create_issue, project).and_return(true)
      expect(helper.show_new_issue_link?(project)).to be_truthy
    end
  end

  describe '#show_moved_service_desk_issue_warning?' do
    let(:project1) { create(:project, service_desk_enabled: true) }
    let(:project2) { create(:project, service_desk_enabled: true) }
    let!(:old_issue) { create(:issue, author: Users::Internal.support_bot, project: project1) }
    let!(:new_issue) { create(:issue, author: Users::Internal.support_bot, project: project2) }

    before do
      allow(Gitlab::Email::IncomingEmail).to receive(:enabled?) { true }
      allow(Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?) { true }

      old_issue.update!(moved_to: new_issue)
    end

    it 'is true when moved issue project has service desk disabled' do
      project2.update!(service_desk_enabled: false)

      expect(helper.show_moved_service_desk_issue_warning?(new_issue)).to be(true)
    end

    it 'is false when moved issue project has service desk enabled' do
      expect(helper.show_moved_service_desk_issue_warning?(new_issue)).to be(false)
    end
  end

  describe '#issue_header_actions_data' do
    let(:current_user) { create(:user) }
    let(:merge_request) { create(:merge_request, :opened, source_project: project, author: current_user) }
    let(:issuable_sidebar_issue) { serialize_issuable_sidebar(current_user, project, merge_request) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:issuable_sidebar).and_return(issuable_sidebar_issue)
    end

    it 'returns expected result' do
      expected = {
        can_create_issue: 'true',
        can_create_incident: 'true',
        can_destroy_issue: 'true',
        can_reopen_issue: 'true',
        can_report_spam: 'false',
        can_update_issue: 'true',
        is_issue_author: 'false',
        issue_path: issue_path(issue),
        new_issue_path: new_project_issue_path(project, { add_related_issue: issue.iid }),
        project_path: project.full_path,
        report_abuse_path: add_category_abuse_reports_path,
        reported_user_id: issue.author.id,
        reported_from_url: issue_url(issue),
        submit_as_spam_path: mark_as_spam_project_issue_path(project, issue),
        issuable_email_address: issuable_sidebar_issue[:create_note_email]
      }

      expect(helper.issue_header_actions_data(project, issue, current_user, issuable_sidebar_issue)).to include(expected)
    end
  end

  shared_examples 'issues list data' do
    it 'returns expected result' do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:image_path).and_return('#')
      allow(helper).to receive(:import_csv_namespace_project_issues_path).and_return('#')
      allow(helper).to receive(:issue_repositioning_disabled?).and_return(true)
      allow(helper).to receive(:url_for).and_return('#')

      expected = {
        autocomplete_award_emojis_path: autocomplete_award_emojis_path,
        calendar_path: '#',
        can_bulk_update: 'true',
        can_create_issue: 'true',
        can_edit: 'true',
        can_import_issues: 'true',
        email: current_user&.notification_email_or_default,
        emails_help_page_path: help_page_path('development/emails.md', anchor: 'email-namespace'),
        export_csv_path: export_csv_project_issues_path(project),
        full_path: project.full_path,
        has_any_issues: project_issues(project).exists?.to_s,
        import_csv_issues_path: '#',
        initial_email: project.new_issuable_address(current_user, 'issue'),
        initial_sort: current_user&.user_preference&.issues_sort,
        is_issue_repositioning_disabled: 'true',
        is_project: 'true',
        is_public_visibility_restricted: Gitlab::CurrentSettings.restricted_visibility_levels ? 'false' : '',
        is_signed_in: current_user.present?.to_s,
        markdown_help_path: help_page_path('user/markdown.md'),
        max_attachment_size: number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes),
        new_issue_path: new_project_issue_path(project),
        project_import_jira_path: project_import_jira_path(project),
        quick_actions_help_path: help_page_path('user/project/quick_actions.md'),
        releases_path: project_releases_path(project, format: :json),
        reset_path: new_issuable_address_project_path(project, issuable_type: 'issue'),
        rss_path: '#',
        show_new_issue_link: 'true',
        sign_in_path: new_user_session_path
      }

      expect(helper.project_issues_list_data(project, current_user)).to include(expected)
    end
  end

  describe '#project_issues_list_data' do
    context 'when user is signed in' do
      it_behaves_like 'issues list data' do
        let(:current_user) { double.as_null_object }
      end
    end

    context 'when user is anonymous' do
      it_behaves_like 'issues list data' do
        let(:current_user) { nil }
      end
    end

    context 'when restricted visibility levels is nil' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:restricted_visibility_levels).and_return(nil)
      end

      it_behaves_like 'issues list data' do
        let(:current_user) { double.as_null_object }
      end
    end
  end

  describe '#group_issues_list_data' do
    let(:current_user) { double.as_null_object }

    it 'returns expected result' do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:image_path).and_return('#')
      allow(helper).to receive(:url_for).and_return('#')

      assign(:has_issues, false)
      assign(:has_projects, true)

      expected = {
        autocomplete_award_emojis_path: autocomplete_award_emojis_path,
        calendar_path: '#',
        can_create_projects: 'true',
        full_path: group.full_path,
        has_any_issues: false.to_s,
        has_any_projects: true.to_s,
        is_signed_in: current_user.present?.to_s,
        new_project_path: new_project_path(namespace_id: group.id),
        rss_path: '#',
        sign_in_path: new_user_session_path,
        group_id: group.id
      }

      expect(helper.group_issues_list_data(group, current_user)).to include(expected)
    end
  end

  describe '#dashboard_issues_list_data' do
    let(:current_user) { double.as_null_object }

    it 'returns expected result' do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:image_path).and_return('#')
      allow(helper).to receive(:url_for).and_return('#')
      stub_feature_flags(issue_date_filter: false)

      expected = {
        autocomplete_award_emojis_path: autocomplete_award_emojis_path,
        calendar_path: '#',
        dashboard_labels_path: dashboard_labels_path(format: :json, include_ancestor_groups: true),
        dashboard_milestones_path: dashboard_milestones_path(format: :json),
        empty_state_with_filter_svg_path: '#',
        empty_state_without_filter_svg_path: '#',
        has_issue_date_filter_feature: 'false',
        initial_sort: current_user&.user_preference&.issues_sort,
        is_public_visibility_restricted: Gitlab::CurrentSettings.restricted_visibility_levels ? 'false' : '',
        is_signed_in: current_user.present?.to_s,
        rss_path: '#'
      }

      expect(helper.dashboard_issues_list_data(current_user)).to include(expected)
    end
  end

  describe '#issues_form_data' do
    it 'returns expected result' do
      expected = {
        new_issue_path: new_project_issue_path(project)
      }

      expect(helper.issues_form_data(project)).to include(expected)
    end
  end

  describe '#issue_repositioning_disabled?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    subject { helper.issue_repositioning_disabled? }

    context 'for project' do
      before do
        assign(:project, project)
      end

      it { is_expected.to eq(false) }

      context 'when block_issue_repositioning feature flag is enabled' do
        before do
          stub_feature_flags(block_issue_repositioning: group)
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'for group' do
      before do
        assign(:group, group)
      end

      it { is_expected.to eq(false) }

      context 'when block_issue_repositioning feature flag is enabled' do
        before do
          stub_feature_flags(block_issue_repositioning: group)
        end

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#issue_hidden?' do
    context 'when issue is hidden' do
      let_it_be(:banned_user) { build(:user, :banned) }
      let_it_be(:hidden_issue) { build(:issue, author: banned_user) }

      it 'returns `true`' do
        expect(helper.issue_hidden?(hidden_issue)).to eq(true)
      end
    end

    context 'when issue is not hidden' do
      it 'returns `false`' do
        expect(helper.issue_hidden?(issue)).to eq(false)
      end
    end
  end

  describe '#has_issue_date_filter_feature?' do
    subject(:has_issue_date_filter_feature) { helper.has_issue_date_filter_feature?(namespace, namespace.owner) }

    context 'when namespace is a group project' do
      let_it_be(:namespace) { create(:project, namespace: group) }

      it { is_expected.to be_truthy }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(issue_date_filter: false)
        end

        it { is_expected.to be_falsey }
      end

      context 'when feature flag enabled for group' do
        before do
          stub_feature_flags(issue_date_filter: [group])
        end

        it { is_expected.to be_truthy }
      end

      context 'when feature flag enabled for user' do
        before do
          stub_feature_flags(issue_date_filter: [namespace.owner])
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when namespace is a group' do
      let_it_be(:namespace) { group }

      subject(:has_issue_date_filter_feature) { helper.has_issue_date_filter_feature?(namespace, user) }

      before_all do
        namespace.add_reporter(user)
      end

      it { is_expected.to be_truthy }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(issue_date_filter: false)
        end

        it { is_expected.to be_falsey }
      end

      context 'when feature flag enabled for group' do
        before do
          stub_feature_flags(issue_date_filter: [group])
        end

        it { is_expected.to be_truthy }
      end

      context 'when feature flag enabled for user' do
        before do
          stub_feature_flags(issue_date_filter: [user])
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when namespace is a user project' do
      let_it_be(:namespace) { project }

      it { is_expected.to be_truthy }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(issue_date_filter: false)
        end

        it { is_expected.to be_falsey }
      end

      context 'when feature flag enabled for user' do
        before do
          stub_feature_flags(issue_date_filter: [project.owner])
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
