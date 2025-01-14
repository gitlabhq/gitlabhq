# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsHelper, feature_category: :code_review_workflow do
  include Users::CalloutsHelper
  include ApplicationHelper
  include PageLayoutHelper
  include ProjectsHelper
  include ProjectForksHelper
  include IconsHelper
  include IssuablesHelper
  include MarkupHelper

  let_it_be(:current_user) { create(:user) }

  describe '#merge_params' do
    let(:merge_request) { create(:merge_request) }

    it 'returns the expected params' do
      expect(merge_params(merge_request)).to eq(
        {
          auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS,
          should_remove_source_branch: true,
          sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
          squash: false
        }
      )
    end
  end

  describe '#format_mr_branch_names' do
    describe 'within the same project' do
      let(:merge_request) { create(:merge_request) }

      subject { format_mr_branch_names(merge_request) }

      it { is_expected.to eq([merge_request.source_branch, merge_request.target_branch]) }
    end

    describe 'within different projects' do
      let(:project) { create(:project) }
      let(:forked_project) { fork_project(project) }
      let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project) }
      subject { format_mr_branch_names(merge_request) }

      let(:source_title) { "#{forked_project.full_path}:#{merge_request.source_branch}" }
      let(:target_title) { "#{project.full_path}:#{merge_request.target_branch}" }

      it { is_expected.to eq([source_title, target_title]) }
    end
  end

  describe '#diffs_tab_pane_data' do
    subject { diffs_tab_pane_data(project, merge_request, {}) }

    context 'for endpoint_diff_for_path' do
      context 'when sub-group project namespace' do
        let_it_be(:group) { create(:group, :public) }
        let_it_be(:subgroup) { create(:group, :private, parent: group) }
        let_it_be(:project) { create(:project, :private, group: subgroup) }
        let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

        it 'returns expected values' do
          expect(
            subject[:endpoint_diff_for_path]
          ).to include("#{project.full_path}/-/merge_requests/#{merge_request.iid}/diff_for_path.json")
        end
      end
    end
  end

  describe '#merge_path_description' do
    # Using let_it_be(:project) raises the following error, so we use need to use let(:project):
    #  ActiveRecord::InvalidForeignKey:
    #    PG::ForeignKeyViolation: ERROR:  insert or update on table "fork_network_members" violates foreign key
    #      constraint "fk_rails_a40860a1ca"
    #    DETAIL:  Key (fork_network_id)=(8) is not present in table "fork_networks".
    let(:project) { create(:project) }
    let(:forked_project) { fork_project(project) }
    let(:merge_request_forked) { create(:merge_request, source_project: forked_project, target_project: project) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    where(:case_name, :mr, :with_arrow, :result) do
      [
        ['forked with arrow', ref(:merge_request_forked), true, lazy do
                                                                  "Project:Branches: #{
          mr.source_project_path}:#{mr.source_branch} → #{
          mr.target_project.full_path}:#{mr.target_branch}"
                                                                end],
        ['forked default', ref(:merge_request_forked), false, lazy do
                                                                "Project:Branches: #{
          mr.source_project_path}:#{mr.source_branch} to #{
            mr.target_project.full_path}:#{mr.target_branch}"
                                                              end],
        ['with arrow', ref(:merge_request), true, lazy { "Branches: #{mr.source_branch} → #{mr.target_branch}" }],
        ['default', ref(:merge_request), false, lazy { "Branches: #{mr.source_branch} to #{mr.target_branch}" }]
      ]
    end

    with_them do
      subject { merge_path_description(mr, with_arrow: with_arrow) }

      it { is_expected.to eq(result) }
    end
  end

  describe '#tab_link_for' do
    let(:merge_request) { create(:merge_request, :simple) }
    let(:options) { {} }

    subject { tab_link_for(merge_request, :show, options) { 'Discussion' } }

    describe 'supports the :force_link option' do
      let(:options) { { force_link: true } }

      it 'removes the data-toggle attributes' do
        is_expected.not_to match(/data-toggle="tabvue"/)
      end
    end
  end

  describe '#user_merge_requests_counts' do
    let(:user) do
      double(
        assigned_open_merge_requests_count: 1,
        review_requested_open_merge_requests_count: 2
      )
    end

    subject { helper.user_merge_requests_counts }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it "returns assigned, review requested and total merge request counts" do
      expect(subject).to eq(
        assigned: user.assigned_open_merge_requests_count,
        review_requested: user.review_requested_open_merge_requests_count,
        total: user.assigned_open_merge_requests_count + user.review_requested_open_merge_requests_count
      )
    end
  end

  describe '#reviewers_label' do
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:reviewer1) { build_stubbed(:user, name: 'Jane Doe') }
    let(:reviewer2) { build_stubbed(:user, name: 'John Doe') }

    before do
      allow(merge_request).to receive(:reviewers).and_return(reviewers)
    end

    context 'when multiple reviewers exist' do
      let(:reviewers) { [reviewer1, reviewer2] }

      it 'returns reviewer label with reviewer names' do
        expect(helper.reviewers_label(merge_request)).to eq("Reviewers: Jane Doe and John Doe")
      end

      it 'returns reviewer label only with include_value: false' do
        expect(helper.reviewers_label(merge_request, include_value: false)).to eq("Reviewers")
      end

      context 'when the name contains a URL' do
        let(:reviewers) { [build_stubbed(:user, name: 'www.gitlab.com')] }

        it 'returns sanitized name' do
          expect(helper.reviewers_label(merge_request)).to eq("Reviewer: www_gitlab_com")
        end
      end
    end

    context 'when one reviewer exists' do
      let(:reviewers) { [reviewer1] }

      it 'returns reviewer label with no names' do
        expect(helper.reviewers_label(merge_request)).to eq("Reviewer: Jane Doe")
      end

      it 'returns reviewer label only with include_value: false' do
        expect(helper.reviewers_label(merge_request, include_value: false)).to eq("Reviewer")
      end
    end

    context 'when no reviewers exist' do
      let(:reviewers) { [] }

      it 'returns reviewer label with no names' do
        expect(helper.reviewers_label(merge_request)).to eq("Reviewers: ")
      end

      it 'returns reviewer label only with include_value: false' do
        expect(helper.reviewers_label(merge_request, include_value: false)).to eq("Reviewers")
      end
    end
  end

  describe '#merge_request_source_branch' do
    let(:malicious_branch_name) { 'name<script>test</script>' }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:forked_project) { fork_project(project) }
    let(:merge_request_forked) do
      create(
        :merge_request,
        source_project: forked_project,
        source_branch: malicious_branch_name,
        target_project: project
      )
    end

    context 'when merge request is a fork' do
      subject { merge_request_source_branch(merge_request_forked) }

      it 'does show the fork icon' do
        expect(subject).to match(/fork/)
      end

      it 'escapes properly' do
        expect(subject).to include(html_escape(malicious_branch_name))
      end
    end

    context 'when merge request is not a fork' do
      subject { merge_request_source_branch(merge_request) }

      it 'does not show the fork icon' do
        expect(subject).not_to match(/fork/)
      end
    end
  end

  describe '#sticky_header_data' do
    let_it_be(:project) { create(:project) }
    let(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, imported_from: imported_from)
    end

    subject { sticky_header_data(project, merge_request) }

    context 'when the merge request is not imported' do
      let(:imported_from) { :none }

      it 'returns data with imported set as false' do
        expect(subject[:imported]).to eq('false')
      end
    end

    context 'when the merge request is imported' do
      let(:imported_from) { :gitlab_migration }

      it 'returns data with imported set as true' do
        expect(subject[:imported]).to eq('true')
      end
    end
  end

  describe '#tab_count_display' do
    let(:merge_request) { create(:merge_request) }

    context 'when merge request is preparing' do
      before do
        allow(merge_request).to receive(:preparing?).and_return(true)
      end

      it { expect(tab_count_display(merge_request, 0)).to eq('-') }
      it { expect(tab_count_display(merge_request, '0')).to eq('-') }
    end

    context 'when merge request is prepared' do
      it { expect(tab_count_display(merge_request, 10)).to eq(10) }
      it { expect(tab_count_display(merge_request, '10')).to eq('10') }
    end
  end

  describe '#allow_collaboration_unavailable_reason' do
    subject { allow_collaboration_unavailable_reason(merge_request) }

    let(:merge_request) do
      create(:merge_request, author: author, source_project: project, source_branch: generate(:branch))
    end

    let_it_be(:public_project) { create(:project, :small_repo, :public) }
    let(:project) { public_project }
    let(:forked_project) { fork_project(project) }
    let(:author) { project.creator }

    context 'when the merge request allows collaboration for the user' do
      before do
        allow(merge_request).to receive(:can_allow_collaboration?).with(current_user).and_return(true)
      end

      it { is_expected.to be_nil }
    end

    context 'when the project is private' do
      let(:project) { create(:project, :empty_repo, :private) }

      it { is_expected.to eq(_('Not available for private projects')) }
    end

    context 'when the source branch is protected' do
      let!(:protected_branch) { create(:protected_branch, project: project, name: merge_request.source_branch) }

      it { is_expected.to eq(_('Not available for protected branches')) }
    end

    context 'when the merge request author cannot push to the source project' do
      let(:author) { create(:user) }

      it { is_expected.to eq(_('Merge request author cannot push to target project')) }
    end
  end

  describe '#project_merge_requests_list_data' do
    let(:project) { create(:project) }

    subject { helper.project_merge_requests_list_data(project, current_user) }

    before do
      allow(helper).to receive(:project).and_return(project)
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).with(current_user, :create_merge_request_in, project).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :admin_merge_request, project).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :create_merge_request_from, project).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :create_merge_request_in, project).and_return(true)
      allow(helper).to receive(:issuables_count_for_state).and_return(5)
      allow(helper).to receive(:url_for).and_return("/rss-url")
      allow(helper).to receive(:export_csv_project_merge_requests_path).and_return('/csv-url')
    end

    it 'returns the correct data' do
      expected_data = {
        autocomplete_award_emojis_path: autocomplete_award_emojis_path,
        full_path: project.full_path,
        is_public_visibility_restricted: 'false',
        is_signed_in: 'true',
        has_any_merge_requests: 'false',
        initial_sort: nil,
        new_merge_request_path: project_new_merge_request_path(project),
        show_export_button: 'true',
        issuable_type: :merge_request,
        email: current_user.notification_email_or_default,
        export_csv_path: '/csv-url',
        rss_url: '/rss-url',
        releases_endpoint: project_releases_path(project, format: :json),
        can_bulk_update: 'true',
        environment_names_path: unfoldered_environment_names_project_path(project, format: :json),
        default_branch: project.default_branch
      }

      expect(subject).to include(expected_data)
    end
  end

  describe '#project_merge_requests_list_more_actions_data' do
    let(:project) { create(:project) }

    subject { helper.project_merge_requests_list_more_actions_data(project, current_user) }

    before do
      allow(helper).to receive(:project).and_return(project)
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:issuables_count_for_state).and_return(5)
      allow(helper).to receive(:url_for).and_return("/rss-url")
      allow(helper).to receive(:export_csv_project_merge_requests_path).and_return('/csv-url')
    end

    it 'returns the correct data' do
      expected_data = {
        is_signed_in: 'true',
        issuable_type: :merge_request,
        issuable_count: 5,
        email: current_user.notification_email_or_default,
        export_csv_path: '/csv-url',
        rss_url: '/rss-url'
      }

      expect(subject).to eq(expected_data)
    end
  end

  describe '#identity_verification_alert_data' do
    let_it_be(:current_user) { build_stubbed(:user) }
    let(:merge_request) { build_stubbed(:merge_request, author: current_user) }

    subject { helper.identity_verification_alert_data(merge_request) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    it 'returns the correct data' do
      expected_data = { identity_verification_required: 'false' }

      expect(subject).to include(expected_data)
    end
  end

  describe '#show_mr_dashboard_banner?' do
    include ApplicationHelper

    using RSpec::Parameterized::TableSyntax

    where(:query_string, :feature_flag_enabled, :search_page, :user_dismissed, :should_show) do
      { assignee_user: 'test' } | true  | true  | false | true
      { assignee_user: 'test' } | false | true  | false | false
      { assignee_user: 'test' } | false | false | false | false
      { assignee_user: 'test' } | false | false | true  | false
      nil                       | false | false | false | false
    end

    with_them do
      before do
        stub_feature_flags(merge_request_dashboard: feature_flag_enabled)
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper).to receive(:user_dismissed?)
          .with(Users::CalloutsHelper::NEW_MR_DASHBOARD_BANNER).and_return(user_dismissed)
        allow(helper).to receive(:request).and_return(double(query_string: query_string))
        allow(helper).to receive(:current_page?)
          .with(Gitlab::Routing.url_helpers.merge_requests_search_dashboard_path).and_return(search_page)
      end

      it do
        expect(helper.show_mr_dashboard_banner?).to eq(should_show)
      end
    end
  end

  describe '#group_merge_requests_list_data' do
    let(:group) { create(:group) }

    subject { helper.group_merge_requests_list_data(group, current_user) }

    before do
      helper.instance_variable_set(:@projects, [])

      allow(helper).to receive(:project).and_return(group)
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:issuables_count_for_state).and_return(5)
      allow(helper).to receive(:url_for).and_return("/rss-url")
    end

    it 'returns the correct data' do
      expected_data = {
        group_id: group.id,
        full_path: group.full_path,
        show_new_resource_dropdown: "false",
        autocomplete_award_emojis_path: autocomplete_award_emojis_path,
        has_any_merge_requests: "false",
        initial_sort: nil,
        is_public_visibility_restricted: 'false',
        is_signed_in: 'true',
        issuable_type: :merge_request,
        email: current_user.notification_email_or_default,
        rss_url: "/rss-url",
        releases_endpoint: group_releases_path(group, format: :json),
        can_bulk_update: "false",
        environment_names_path: unfoldered_environment_names_group_path(group, :json)
      }

      expect(subject).to include(expected_data)
    end
  end
end
