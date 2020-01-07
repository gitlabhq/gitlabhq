# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::Projects::GrafanaIntegrationResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:grafana_integration) { create(:grafana_integration, project: project)}

  describe '#resolve' do
    context 'when object is not a project' do
      it { expect(resolve_integration(obj: current_user)).to eq nil }
    end

    context 'when object is a project' do
      it { expect(resolve_integration(obj: project)).to eq grafana_integration }
    end

    context 'when object is nil' do
      it { expect(resolve_integration(obj: nil)).to eq nil}
    end
  end

  def resolve_integration(obj: project, context: { current_user: current_user })
    resolve(described_class, obj: obj, ctx: context)
  end
end
