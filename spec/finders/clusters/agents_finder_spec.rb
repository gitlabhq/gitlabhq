# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentsFinder do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:user) { create(:user, maintainer_of: project) }

    let!(:matching_agent) { create(:cluster_agent, project: project) }
    let!(:wrong_project) { create(:cluster_agent) }

    subject { described_class.new(project, user).execute }

    it { is_expected.to contain_exactly(matching_agent) }

    context 'user does not have permission' do
      let(:user) { create(:user) }

      before do
        project.add_reporter(user)
      end

      it { is_expected.to be_empty }
    end

    context 'filtering by name' do
      let(:params) { Hash(name: name_param) }

      subject { described_class.new(project, user, params: params).execute }

      context 'name does not match' do
        let(:name_param) { 'other-name' }

        it { is_expected.to be_empty }
      end

      context 'name does match' do
        let(:name_param) { matching_agent.name }

        it { is_expected.to contain_exactly(matching_agent) }
      end
    end
  end
end
