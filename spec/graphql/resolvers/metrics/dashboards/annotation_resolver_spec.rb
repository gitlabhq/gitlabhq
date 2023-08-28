# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Metrics::Dashboards::AnnotationResolver, feature_category: :metrics do
  include GraphqlHelpers

  describe '#resolve' do
    context 'user with developer access' do
      subject(:resolve_annotations) { resolve(described_class, obj: nil, args: args, ctx: { current_user: current_user }) }

      let_it_be(:current_user) { create(:user) }
      let_it_be(:environment) { create(:environment) }
      let_it_be(:path) { 'config/prometheus/common_metrics.yml' }

      let(:args) do
        {
          from: 10.minutes.ago,
          to: 5.minutes.ago
        }
      end

      before_all do
        environment.project.add_developer(current_user)
      end

      context 'with annotation records' do
        it 'returns empty all the time' do
          expect(resolve_annotations).to be_empty
        end
      end
    end
  end
end
