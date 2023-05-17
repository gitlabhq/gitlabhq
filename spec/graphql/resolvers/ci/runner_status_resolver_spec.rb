# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerStatusResolver, feature_category: :runner_fleet do
  include GraphqlHelpers

  describe '#resolve' do
    let(:user) { build(:user) }
    let(:runner) { build(:ci_runner) }

    subject(:resolve_subject) { resolve(described_class, ctx: { current_user: user }, obj: runner) }

    it 'calls runner.status and returns it' do
      expect(runner).to receive(:status).once.and_return(:stale)

      expect(resolve_subject).to eq(:stale)
    end
  end
end
