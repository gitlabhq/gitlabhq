# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::PlanLimitsResolver, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let(:project) { build(:project, :repository) }

  describe 'Pipeline schedule limits' do
    before do
      project.add_owner(user)
    end

    it 'gets the current limits for pipeline schedules' do
      limits = resolve_plan_limits

      expect(limits).to include({ ci_pipeline_schedules: project.actual_limits.ci_pipeline_schedules })
    end
  end

  describe 'Pipeline schedule limits without authorization' do
    it 'returns a ResourceNotAvailable error' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
        resolve_plan_limits
      end
    end

    it 'returns null when a user is not allowed to see the limit but allowed to see project' do
      project.add_reporter(user)

      limits = resolve_plan_limits

      expect(limits).to include({ ci_pipeline_schedules: nil })
    end
  end

  def resolve_plan_limits(args: {})
    resolve(described_class, obj: project, ctx: { current_user: user }, args: args)
  end
end
