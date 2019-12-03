# frozen_string_literal: true

require 'spec_helper'

describe DeploymentsFinder do
  subject { described_class.new(project, params).execute }

  let(:project) { create(:project, :public, :repository) }
  let(:params) { {} }

  describe "#execute" do
    it 'returns all deployments by default' do
      deployments = create_list(:deployment, 2, :success, project: project)
      is_expected.to match_array(deployments)
    end

    describe 'filtering' do
      context 'when updated_at filters are specified' do
        let(:params) { { updated_before: 1.day.ago, updated_after: 3.days.ago } }
        let!(:deployment_1) { create(:deployment, :success, project: project, updated_at: 2.days.ago) }
        let!(:deployment_2) { create(:deployment, :success, project: project, updated_at: 4.days.ago) }
        let!(:deployment_3) { create(:deployment, :success, project: project, updated_at: 1.hour.ago) }

        it 'returns deployments with matched updated_at' do
          is_expected.to match_array([deployment_1])
        end
      end
    end

    describe 'ordering' do
      using RSpec::Parameterized::TableSyntax

      let(:params) { { order_by: order_by, sort: sort } }

      let!(:deployment_1) { create(:deployment, :success, project: project, iid: 11, ref: 'master', created_at: Time.now, updated_at: Time.now) }
      let!(:deployment_2) { create(:deployment, :success, project: project, iid: 12, ref: 'feature', created_at: 1.day.ago, updated_at: 2.hours.ago) }
      let!(:deployment_3) { create(:deployment, :success, project: project, iid: 8, ref: 'patch', created_at: 2.days.ago, updated_at: 1.hour.ago) }

      where(:order_by, :sort, :ordered_deployments) do
        'created_at' | 'asc'  | [:deployment_3, :deployment_2, :deployment_1]
        'created_at' | 'desc' | [:deployment_1, :deployment_2, :deployment_3]
        'id'         | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
        'id'         | 'desc' | [:deployment_3, :deployment_2, :deployment_1]
        'iid'        | 'asc'  | [:deployment_3, :deployment_1, :deployment_2]
        'iid'        | 'desc' | [:deployment_2, :deployment_1, :deployment_3]
        'ref'        | 'asc'  | [:deployment_2, :deployment_1, :deployment_3]
        'ref'        | 'desc' | [:deployment_3, :deployment_1, :deployment_2]
        'updated_at' | 'asc'  | [:deployment_2, :deployment_3, :deployment_1]
        'updated_at' | 'desc' | [:deployment_1, :deployment_3, :deployment_2]
        'invalid'    | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
        'iid'        | 'err'  | [:deployment_3, :deployment_1, :deployment_2]
      end

      with_them do
        it 'returns the deployments ordered' do
          expect(subject).to eq(ordered_deployments.map { |name| public_send(name) })
        end
      end
    end
  end
end
