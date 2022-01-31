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

  describe '#record_conversion' do
    let_it_be(:namespace) { create(:namespace) }

    context 'when should_track? is false' do
      before do
        allow(experiment).to receive(:should_track?).and_return(false)
      end

      it 'does not record a conversion event' do
        expect(experiment.publish_to_database).to be_nil
        expect(experiment.record_conversion(namespace)).to be_nil
      end
    end

    context 'when should_track? is true' do
      before do
        allow(experiment).to receive(:should_track?).and_return(true)
      end

      it 'records a conversion event' do
        experiment_subject = experiment.publish_to_database

        expect { experiment.record_conversion(namespace) }.to change { experiment_subject.reload.converted_at }.from(nil)
          .and change { experiment_subject.context }.to include('namespace_id' => namespace.id)
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
