# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StatesFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:state_1) { create(:terraform_state, project: project) }
    let_it_be(:state_2) { create(:terraform_state, project: project) }

    let(:user) { project.creator }

    subject { described_class.new(project, user).execute }

    it { is_expected.to contain_exactly(state_1, state_2) }

    context 'user does not have permission' do
      let(:user) { create(:user) }

      before do
        project.add_guest(user)
      end

      it { is_expected.to be_empty }
    end

    context 'filtering by name' do
      let(:params) { { name: name_param } }

      subject { described_class.new(project, user, params: params).execute }

      context 'name does not match' do
        let(:name_param) { 'other-name' }

        it { is_expected.to be_empty }
      end

      context 'name does match' do
        let(:name_param) { state_1.name }

        it { is_expected.to contain_exactly(state_1) }
      end
    end
  end
end
