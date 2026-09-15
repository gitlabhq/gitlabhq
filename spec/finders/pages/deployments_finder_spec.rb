# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeploymentsFinder, feature_category: :pages do
  # Most of Pages::DeploymentsFinder is tested with the GraphQL request specs
  # so this spec will only test remaining conditions that cannot be
  # tested otherwise.

  it 'execute throws an error when passed a parent that\'s not of type Project or Namespace' do
    expect { described_class.new("Foo").execute }.to raise_error(
      RuntimeError, "Pages::DeploymentsFinder only supports Namespace or Projects as parent"
    )
  end

  describe 'filtering by active status' do
    let_it_be(:project) { create(:project) }
    let_it_be(:active_deployment) { create(:pages_deployment, project: project) }
    let_it_be(:inactive_deployment) { create(:pages_deployment, project: project, deleted_at: Time.zone.now) }

    it 'returns all deployments when active param is not provided' do
      result = described_class.new(project).execute

      expect(result).to include(active_deployment, inactive_deployment)
    end

    it 'returns only active deployments when active is true' do
      result = described_class.new(project, active: true).execute

      expect(result).to contain_exactly(active_deployment)
    end

    it 'returns only inactive deployments when active is false' do
      result = described_class.new(project, active: false).execute

      expect(result).to contain_exactly(inactive_deployment)
    end
  end
end
