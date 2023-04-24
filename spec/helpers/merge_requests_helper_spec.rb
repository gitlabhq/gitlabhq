# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsHelper, feature_category: :code_review_workflow do
  include Users::CalloutsHelper
  include ApplicationHelper
  include PageLayoutHelper
  include ProjectsHelper
  include ProjectForksHelper
  include IconsHelper

  let_it_be(:current_user) { create(:user) }

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

      it {
        is_expected.to eq(result)
      }
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
    let_it_be(:project) { create(:project) }
    let(:forked_project) { fork_project(project) }
    let(:merge_request_forked) { create(:merge_request, source_project: forked_project, target_project: project) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    context 'when merge request is a fork' do
      subject { merge_request_source_branch(merge_request_forked) }

      it 'does show the fork icon' do
        expect(subject).to match(/fork/)
      end
    end

    context 'when merge request is not a fork' do
      subject { merge_request_source_branch(merge_request) }

      it 'does not show the fork icon' do
        expect(subject).not_to match(/fork/)
      end
    end
  end
end
