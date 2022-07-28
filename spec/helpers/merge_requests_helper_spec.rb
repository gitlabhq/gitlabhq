# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsHelper do
  include ProjectForksHelper

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

  describe '#merge_path_description' do
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
        review_requested_open_merge_requests_count: 2,
        attention_requested_open_merge_requests_count: 3
      )
    end

    subject { helper.user_merge_requests_counts }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    describe 'mr_attention_requests disabled' do
      before do
        allow(user).to receive(:mr_attention_requests_enabled?).and_return(false)
      end

      it "returns assigned, review requested and total merge request counts" do
        expect(subject).to eq(
          assigned: user.assigned_open_merge_requests_count,
          review_requested: user.review_requested_open_merge_requests_count,
          total: user.assigned_open_merge_requests_count + user.review_requested_open_merge_requests_count
        )
      end
    end

    describe 'mr_attention_requests enabled' do
      before do
        allow(user).to receive(:mr_attention_requests_enabled?).and_return(true)
      end

      it "returns assigned, review requested, attention requests and total merge request counts" do
        expect(subject).to eq(
          assigned: user.assigned_open_merge_requests_count,
          review_requested: user.review_requested_open_merge_requests_count,
          attention_requested_count: user.attention_requested_open_merge_requests_count,
          total: user.attention_requested_open_merge_requests_count
        )
      end
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
end
