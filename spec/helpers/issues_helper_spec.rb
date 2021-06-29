# frozen_string_literal: true

require "spec_helper"

RSpec.describe IssuesHelper do
  let(:project) { create(:project) }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

  describe '#award_user_list' do
    it "returns a comma-separated list of the first X users" do
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

    it "truncates lists" do
      user = build_stubbed(:user, name: 'Jane')
      awards = Array.new(5, build_stubbed(:award_emoji, user: user))

      expect(award_user_list(awards, nil, limit: 3))
        .to eq('Jane, Jane, Jane, and 2 more.')
    end

    it "displays the current user in front of other users" do
      current_user = build_stubbed(:user)
      my_award = build_stubbed(:award_emoji, user: current_user)
      award = build_stubbed(:award_emoji, user: build_stubbed(:user, name: 'Jane'))
      awards = Array.new(5, award).push(my_award)

      expect(award_user_list(awards, current_user, limit: 2))
        .to eq("You, Jane, and 4 more.")
    end
  end

  describe '#award_state_class' do
    let!(:upvote) { create(:award_emoji) }
    let(:awardable) { upvote.awardable }
    let(:user) { upvote.user }

    before do
      allow(helper).to receive(:can?) do |*args|
        Ability.allowed?(*args)
      end
    end

    it "returns disabled string for unauthenticated user" do
      expect(helper.award_state_class(awardable, AwardEmoji.all, nil)).to eq("disabled")
    end

    it "returns disabled for a user that does not have access to the awardable" do
      expect(helper.award_state_class(awardable, AwardEmoji.all, build(:user))).to eq("disabled")
    end

    it "returns active string for author" do
      expect(helper.award_state_class(awardable, AwardEmoji.all, upvote.user)).to eq("active")
    end

    it "is blank for a user that has access to the awardable" do
      user = build(:user)
      expect(helper).to receive(:can?).with(user, :award_emoji, awardable).and_return(true)

      expect(helper.award_state_class(awardable, AwardEmoji.all, user)).to be_blank
    end
  end

  describe "awards_sort" do
    it "sorts a hash so thumbsup and thumbsdown are always on top" do
      data = { "thumbsdown" => "some value", "lifter" => "some value", "thumbsup" => "some value" }
      expect(awards_sort(data).keys).to eq(%w(thumbsup thumbsdown lifter))
    end
  end

  describe "#link_to_discussions_to_resolve" do
    describe "passing only a merge request" do
      let(:merge_request) { create(:merge_request) }

      it "links just the merge request" do
        expected_path = project_merge_request_path(merge_request.project, merge_request)

        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(expected_path)
      end

      it "contains the reference to the merge request" do
        expect(link_to_discussions_to_resolve(merge_request, nil)).to include(merge_request.to_reference)
      end
    end

    describe "when passing a discussion" do
      let(:diff_note) { create(:diff_note_on_merge_request) }
      let(:merge_request) { diff_note.noteable }
      let(:discussion) { diff_note.to_discussion }

      it "links to the merge request with first note if a single discussion was passed" do
        expected_path = Gitlab::UrlBuilder.build(diff_note)

        expect(link_to_discussions_to_resolve(merge_request, discussion)).to include(expected_path)
      end

      it "contains both the reference to the merge request and a mention of the discussion" do
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

  describe '#issue_closed_link' do
    let(:new_issue) { create(:issue, project: project) }
    let(:guest)     { create(:user) }

    before do
      allow(helper).to receive(:can?) do |*args|
        Ability.allowed?(*args)
      end
    end

    shared_examples 'successfully displays link to issue and with css class' do |action|
      it 'returns link' do
        link = "<a class=\"#{css_class}\" href=\"/#{new_issue.project.full_path}/-/issues/#{new_issue.iid}\">(#{action})</a>"

        expect(helper.issue_closed_link(issue, user, css_class: css_class)).to match(link)
      end
    end

    shared_examples 'does not display link' do
      it 'returns nil' do
        expect(helper.issue_closed_link(issue, user)).to be_nil
      end
    end

    context 'with linked issue' do
      context 'with moved issue' do
        before do
          issue.update!(moved_to: new_issue)
        end

        context 'when user has permission to see new issue' do
          let(:user)      { project.owner }
          let(:css_class) { 'text-white text-underline' }

          it_behaves_like 'successfully displays link to issue and with css class', 'moved'
        end

        context 'when user has no permission to see new issue' do
          let(:user) { guest }

          it_behaves_like 'does not display link'
        end
      end

      context 'with duplicated issue' do
        before do
          issue.update!(duplicated_to: new_issue)
        end

        context 'when user has permission to see new issue' do
          let(:user)      { project.owner }
          let(:css_class) { 'text-white text-underline' }

          it_behaves_like 'successfully displays link to issue and with css class', 'duplicated'
        end

        context 'when user has no permission to see new issue' do
          let(:user) { guest }

          it_behaves_like 'does not display link'
        end
      end
    end

    context 'without linked issue' do
      let(:user) { project.owner }

      before do
        issue.update!(moved_to: nil, duplicated_to: nil)
      end

      it_behaves_like 'does not display link'
    end
  end

  describe '#show_moved_service_desk_issue_warning?' do
    let(:project1) { create(:project, service_desk_enabled: true) }
    let(:project2) { create(:project, service_desk_enabled: true) }
    let!(:old_issue) { create(:issue, author: User.support_bot, project: project1) }
    let!(:new_issue) { create(:issue, author: User.support_bot, project: project2) }

    before do
      allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
      allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

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

  describe '#use_startup_call' do
    it "returns false when a query param is present" do
      allow(controller.request).to receive(:query_parameters).and_return({ foo: 'bar' })

      expect(helper.use_startup_call?).to eq(false)
    end

    it "returns false when user has stored sort preference" do
      controller.instance_variable_set(:@sort, 'updated_asc')

      expect(helper.use_startup_call?).to eq(false)
    end

    it 'returns true when request.query_parameters is empty with default sorting preference' do
      controller.instance_variable_set(:@sort, 'created_date')
      allow(controller.request).to receive(:query_parameters).and_return({})

      expect(helper.use_startup_call?).to eq(true)
    end
  end

  describe '#issue_header_actions_data' do
    let(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns expected result' do
      expected = {
        can_create_issue: "true",
        can_reopen_issue: "true",
        can_report_spam: "false",
        can_update_issue: "true",
        iid: issue.iid,
        is_issue_author: "false",
        issue_type: "issue",
        new_issue_path: new_project_issue_path(project),
        project_path: project.full_path,
        report_abuse_path: new_abuse_report_path(user_id: issue.author.id, ref_url: issue_url(issue)),
        submit_as_spam_path: mark_as_spam_project_issue_path(project, issue)
      }

      expect(helper.issue_header_actions_data(project, issue, current_user)).to include(expected)
    end
  end

  shared_examples 'issues list data' do
    it 'returns expected result' do
      finder = double.as_null_object
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:finder).and_return(finder)
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:image_path).and_return('#')
      allow(helper).to receive(:import_csv_namespace_project_issues_path).and_return('#')
      allow(helper).to receive(:url_for).and_return('#')

      expected = {
        autocomplete_award_emojis_path: autocomplete_award_emojis_path,
        calendar_path: '#',
        can_bulk_update: 'true',
        can_edit: 'true',
        can_import_issues: 'true',
        email: current_user&.notification_email,
        emails_help_page_path: help_page_path('development/emails', anchor: 'email-namespace'),
        empty_state_svg_path: '#',
        export_csv_path: export_csv_project_issues_path(project),
        has_project_issues: project_issues(project).exists?.to_s,
        import_csv_issues_path: '#',
        initial_email: project.new_issuable_address(current_user, 'issue'),
        is_signed_in: current_user.present?.to_s,
        issues_path: project_issues_path(project),
        jira_integration_path: help_page_url('integration/jira/', anchor: 'view-jira-issues'),
        markdown_help_path: help_page_path('user/markdown'),
        max_attachment_size: number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes),
        new_issue_path: new_project_issue_path(project, issue: { milestone_id: finder.milestones.first.id }),
        project_import_jira_path: project_import_jira_path(project),
        project_path: project.full_path,
        quick_actions_help_path: help_page_path('user/project/quick_actions'),
        reset_path: new_issuable_address_project_path(project, issuable_type: 'issue'),
        rss_path: '#',
        show_new_issue_link: 'true',
        sign_in_path: new_user_session_path
      }

      expect(helper.issues_list_data(project, current_user, finder)).to include(expected)
    end
  end

  describe '#issues_list_data' do
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
  end

  describe '#issue_manual_ordering_class' do
    context 'when sorting by relative position' do
      before do
        assign(:sort, 'relative_position')
      end

      it 'returns manual ordering class' do
        expect(helper.issue_manual_ordering_class).to eq("manual-ordering")
      end

      context 'when manual sorting disabled' do
        before do
          allow(helper).to receive(:issue_repositioning_disabled?).and_return(true)
        end

        it 'returns nil' do
          expect(helper.issue_manual_ordering_class).to eq(nil)
        end
      end
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
end
