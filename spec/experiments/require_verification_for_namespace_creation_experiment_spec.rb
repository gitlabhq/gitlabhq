# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequireVerificationForNamespaceCreationExperiment, :experiment do
  subject(:experiment) { described_class.new(user: user) }

  let(:user_created_at) { RequireVerificationForNamespaceCreationExperiment::EXPERIMENT_START_DATE + 1.hour }
  let(:user) { create(:user, created_at: user_created_at) }

  describe '#candidate?' do
    context 'when experiment subject is candidate' do
      before do
        stub_experiments(require_verification_for_namespace_creation: :candidate)
      end

      it 'returns true' do
        expect(experiment.candidate?).to eq(true)
      end
    end

    context 'when experiment subject is control' do
      before do
        stub_experiments(require_verification_for_namespace_creation: :control)
      end

      it 'returns false' do
        expect(experiment.candidate?).to eq(false)
      end
    end
  end

  describe 'exclusions' do
    context 'when user is new' do
      it 'is not excluded' do
        expect(subject).not_to exclude(user: user)
      end
    end

    context 'when user is NOT new' do
      let(:user_created_at) { RequireVerificationForNamespaceCreationExperiment::EXPERIMENT_START_DATE - 1.day }
      let(:user) { create(:user, created_at: user_created_at) }

      it 'is excluded' do
        expect(subject).to exclude(user: user)
      end
    end
  end
end
