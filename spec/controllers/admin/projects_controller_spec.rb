# frozen_string_literal: true

require 'spec_helper'

# The show, transfer, and destroy actions were migrated to the request spec at
# spec/requests/admin/projects_controller_spec.rb as part of the
# controller-to-request spec migration (https://gitlab.com/groups/gitlab-org/-/epics/5076).
# The examples that remain here unit-test private strong-parameter filtering
# methods, which have no request-spec equivalent.
RSpec.describe Admin::ProjectsController, feature_category: :groups_and_projects do
  describe '#project_identifier_params' do
    it 'permits only namespace_id and id parameters' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          namespace_id: 'namespace',
          id: 'project',
          new_namespace_id: 123,
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:project_identifier_params)

      expect(result.keys).to contain_exactly('namespace_id', 'id')
      expect(result[:namespace_id]).to eq('namespace')
      expect(result[:id]).to eq('project')
      expect(result[:new_namespace_id]).to be_nil
      expect(result[:extra_param]).to be_nil
      expect(result[:malicious]).to be_nil
      expect(result.permitted?).to be true
    end
  end

  describe '#transfer_params' do
    it 'permits only new_namespace_id parameter' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          new_namespace_id: 123,
          namespace_id: 'namespace',
          id: 'project',
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:transfer_params)

      expect(result.keys).to contain_exactly('new_namespace_id')
      expect(result[:new_namespace_id]).to eq(123)
      expect(result[:namespace_id]).to be_nil
      expect(result[:id]).to be_nil
      expect(result[:extra_param]).to be_nil
      expect(result[:malicious]).to be_nil
      expect(result.permitted?).to be true
    end
  end

  describe '#page_params' do
    it 'permits only pagination parameters' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          group_members_page: 1,
          project_members_page: 2,
          namespace_id: 'namespace',
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:page_params)

      expect(result.keys).to contain_exactly('group_members_page', 'project_members_page')
      expect(result[:group_members_page]).to eq(1)
      expect(result[:project_members_page]).to eq(2)
      expect(result[:namespace_id]).to be_nil
      expect(result[:extra_param]).to be_nil
      expect(result[:malicious]).to be_nil
      expect(result.permitted?).to be true
    end
  end
end
