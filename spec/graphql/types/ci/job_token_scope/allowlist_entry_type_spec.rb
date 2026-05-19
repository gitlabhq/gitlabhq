# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenScopeAllowlistEntry'], feature_category: :secrets_management do
  include GraphqlHelpers

  let(:batch_loader) { instance_double(Gitlab::Graphql::Loaders::BatchModelLoader) }

  specify { expect(described_class.graphql_name).to eq('CiJobTokenScopeAllowlistEntry') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      source_project
      target
      direction
      default_permissions
      job_token_policies
      added_by
      created_at
      autopopulated
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#source_project' do
    let_it_be(:link) { create(:ci_job_token_project_scope_link) }

    it 'preloads :route on the source project to avoid N+1 lookups for fullPath' do
      expect(Gitlab::Graphql::Loaders::BatchModelLoader)
        .to receive(:new).with(Project, link.source_project_id, [:route]).and_return(batch_loader)
      expect(batch_loader).to receive(:find)

      resolve_field(:source_project, link)
    end
  end

  describe '#target' do
    context 'when the entry is a project scope link' do
      let_it_be(:project_link) { create(:ci_job_token_project_scope_link) }

      it 'preloads :route on the target project to avoid N+1 lookups for fullPath' do
        expect(Gitlab::Graphql::Loaders::BatchModelLoader)
          .to receive(:new).with(Project, project_link.target_project_id, [:route]).and_return(batch_loader)
        expect(batch_loader).to receive(:find)

        resolve_field(:target, project_link)
      end
    end

    context 'when the entry is a group scope link' do
      let_it_be(:group_link) { create(:ci_job_token_group_scope_link) }

      it 'preloads :route on the target group to avoid N+1 lookups for fullPath' do
        expect(Gitlab::Graphql::Loaders::BatchModelLoader)
          .to receive(:new).with(Group, group_link.target_group_id, [:route]).and_return(batch_loader)
        expect(batch_loader).to receive(:find)

        resolve_field(:target, group_link)
      end
    end
  end
end
