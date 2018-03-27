require 'spec_helper'

describe MergeRequestPolicy do
  include ExternalAuthorizationServiceHelpers

  let(:guest) { create(:user) }
  let(:developer) { create(:user) }
  let(:master) { create(:user) }

  let(:fork_guest) { create(:user) }
  let(:fork_developer) { create(:user) }
  let(:fork_master) { create(:user) }

  let(:project) { create(:project, :public) }
  let(:fork_project) { create(:project, :public, forked_from_project: project) }

  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:fork_merge_request) { create(:merge_request, author: fork_developer, source_project: fork_project, target_project: project) }

  before do
    project.add_guest(guest)
    project.add_developer(developer)
    project.add_master(master)

    fork_project.add_guest(fork_guest)
    fork_project.add_developer(fork_guest)
    fork_project.add_master(fork_master)
  end

  context 'for a merge request within the same project' do
    def policy_for(user)
      described_class.new(user, merge_request)
    end

    context 'when overwriting approvers is disabled on the project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow anyone to update approvers' do
        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(developer)).to be_disallowed(:update_approvers)
        expect(policy_for(master)).to be_disallowed(:update_approvers)

        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_master)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is enabled on the project' do
      it 'allows only project developers and above to update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(master)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_master)).to be_disallowed(:update_approvers)
      end
    end
  end

  context 'for a merge request from a fork' do
    def policy_for(user)
      described_class.new(user, fork_merge_request)
    end

    context 'when overwriting approvers is disabled on the target project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow anyone to update approvers' do
        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(developer)).to be_disallowed(:update_approvers)
        expect(policy_for(master)).to be_disallowed(:update_approvers)

        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_master)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is disabled on the source project' do
      before do
        fork_project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'has no effect - project developers and above, as well as the author, can update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(master)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_master)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is enabled on the target project' do
      it 'allows project developers and above, as well as the author, to update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(master)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_master)).to be_disallowed(:update_approvers)
      end
    end
  end

  context 'with external authorization enabled' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:policies) { described_class.new(user, merge_request) }

    before do
      enable_external_authorization_service_check
    end

    it 'can read the issue iid without accessing the external service' do
      expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(policies).to be_allowed(:read_merge_request_iid)
    end
  end
end
