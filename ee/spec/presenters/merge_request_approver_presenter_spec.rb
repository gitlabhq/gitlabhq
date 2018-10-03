# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestApproverPresenter do
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
  let(:files) do
    [
      double(:file, old_path: 'coo', new_path: nil),
      double(:file, old_path: 'foo', new_path: 'bar'),
      double(:file, old_path: nil, new_path: 'baz')
    ]
  end
  let(:approvals_required) { 10 }
  let(:enable_code_owner_as_approver_suggestion) { true }

  let(:author) { merge_request.author }
  let(:owner_a) { build(:user) }
  let(:owner_b) { build(:user) }
  let(:committer_a) { create(:user) }
  let(:committer_b) { create(:user) }
  let(:code_owner_loader) { double(:loader) }

  subject { described_class.new(merge_request) }

  before do
    diffs = double(:diffs)
    allow(merge_request).to receive(:diffs).and_return(diffs)
    allow(diffs).to receive(:diff_files).and_return(files)

    allow(merge_request).to receive(:approvals_required).and_return(approvals_required)

    stub_licensed_features(code_owner_as_approver_suggestion: enable_code_owner_as_approver_suggestion)
  end

  def expect_code_owner_loader_init
    expect(Gitlab::CodeOwners::Loader).to receive(:new).with(
      merge_request.target_project,
      merge_request.target_branch,
      %w(coo foo bar baz)
    ).and_return(code_owner_loader)
  end

  def expect_code_owners_call(*stub_return_users)
    expect_code_owner_loader_init
    expect(code_owner_loader).to receive(:members).and_return(stub_return_users)
    expect(code_owner_loader).to receive(:non_members).and_return([])
  end

  def expect_git_log_call(*stub_return_users)
    analyzer = double(:analyzer)

    expect(Gitlab::AuthorityAnalyzer).to receive(:new).with(
      merge_request,
      merge_request.author
    ).and_return(analyzer)

    expect(analyzer).to receive(:calculate).and_return(stub_return_users)
  end

  describe '#render' do
    context 'when code owner exists' do
      it 'renders code owners' do
        expect_code_owners_call(owner_a, owner_b)
        expect(subject).to receive(:render_user).with(owner_a).and_call_original
        expect(subject).to receive(:render_user).with(owner_b).and_call_original

        subject.render
      end
    end

    context 'git log lookup' do
      context 'when authors are approvers' do
        before do
          project.add_developer(committer_a)
          project.add_developer(committer_b)
        end

        context 'when the only code owner is skip_user' do
          it 'displays git log authors instead' do
            expect_code_owners_call(merge_request.author)
            expect_git_log_call(committer_a)
            expect(subject).to receive(:render_user).with(committer_a).and_call_original

            subject.render
          end
        end

        context 'when code owners do not exist' do
          it 'displays git log authors' do
            expect_code_owners_call
            expect_git_log_call(committer_a)
            expect(subject).to receive(:render_user).with(committer_a).and_call_original

            subject.render
          end
        end

        context 'approvals_required is low' do
          let(:approvals_required) { 1 }

          it 'returns top n approvers' do
            expect_code_owners_call
            expect_git_log_call(committer_a, committer_b)
            expect(subject).to receive(:render_user).with(committer_a).and_call_original
            expect(subject).not_to receive(:render_user).with(committer_b)

            subject.render
          end
        end
      end

      context 'code_owner_as_approver_suggestion disabled' do
        let(:enable_code_owner_as_approver_suggestion) { false }

        before do
          project.add_developer(committer_a)
        end

        it 'displays git log authors' do
          expect(Gitlab::CodeOwners::Loader).not_to receive(:new)
          expect_git_log_call(committer_a)
          expect(subject).to receive(:render_user).with(committer_a).and_call_original

          subject.render
        end
      end
    end
  end

  describe '#any?' do
    it 'returns true if any user exists' do
      expect_code_owners_call(owner_a)

      expect(subject.any?).to eq(true)
    end

    it 'returns false if no user exists' do
      expect_code_owners_call
      expect_git_log_call

      expect(subject.any?).to eq(false)
    end

    it 'caches loaded users' do
      expect(subject).to receive(:load_users).once.and_call_original

      subject.any?
      subject.any?
    end
  end

  describe '#render_user' do
    it 'renders plaintext if user is not an eligible approver' do
      expect_code_owner_loader_init
      expect(code_owner_loader).to receive(:members).and_return([])
      expect(code_owner_loader).to receive(:non_members).and_return([owner_a])

      result = subject.render_user(owner_a)

      expect(result).to start_with('<span')
      expect(result).to include('has-tooltip')
    end

    context 'user is an eligible approver' do
      it 'renders link' do
        expect_code_owners_call(committer_a)

        result = subject.render_user(committer_a)

        expect(result).to start_with('<a')
      end
    end
  end

  describe '#show_code_owner_tips?' do
    context 'when code_owner feature enabled and code owner is empty' do
      before do
        expect_code_owner_loader_init
        allow(code_owner_loader).to receive(:empty_code_owners?).and_return(true)
      end

      it 'returns true' do
        expect(subject.show_code_owner_tips?).to eq(true)
      end
    end

    context 'when code_owner feature enabled and code owner is not empty' do
      before do
        expect_code_owner_loader_init
        allow(code_owner_loader).to receive(:empty_code_owners?).and_return(false)
      end

      it 'returns false' do
        expect(subject.show_code_owner_tips?).to eq(false)
      end
    end

    context 'when code_owner feature is disabled' do
      let(:enable_code_owner_as_approver_suggestion) { false }

      it 'returns false' do
        expect(subject.show_code_owner_tips?).to eq(false)
      end
    end
  end
end
