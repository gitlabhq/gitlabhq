# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerStatusResolver, feature_category: :runner_fleet do
  include GraphqlHelpers

  describe '#resolve' do
    let(:user) { build(:user) }
    let(:runner) { build(:ci_runner) }

    subject(:resolve_subject) { resolve(described_class, ctx: { current_user: user }, obj: runner, args: args) }

    context 'with legacy_mode' do
      context 'set to 14.5' do
        let(:args) do
          { legacy_mode: '14.5' }
        end

        it 'calls runner.status with nil' do
          expect(runner).to receive(:status).with(nil).once.and_return(:stale)

          expect(resolve_subject).to eq(:stale)
        end

        context 'when disable_runner_graphql_legacy_mode feature is disabled' do
          before do
            stub_feature_flags(disable_runner_graphql_legacy_mode: false)
          end

          it 'calls runner.status with specified legacy_mode' do
            expect(runner).to receive(:status).with('14.5').once.and_return(:online)

            expect(resolve_subject).to eq(:online)
          end
        end
      end

      context 'set to nil' do
        let(:args) do
          { legacy_mode: nil }
        end

        it 'calls runner.status with nil' do
          expect(runner).to receive(:status).with(nil).once.and_return(:stale)

          expect(resolve_subject).to eq(:stale)
        end
      end
    end
  end
end
