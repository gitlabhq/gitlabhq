# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCommitCount do
  let(:klass) { Class.include(ProjectCommitCount) }
  let(:instance) { klass.new }

  describe '#commit_count_for' do
    subject { instance.commit_count_for(project, default_count: 42, caller_info: :identifiable) }

    let(:project) { create(:project, :repository) }

    context 'when a root_ref exists' do
      it 'returns commit count from GitlayClient' do
        allow(Gitlab::GitalyClient).to receive(:call).and_call_original
        allow(Gitlab::GitalyClient).to receive(:call).with(anything, :commit_service, :count_commits, anything, anything)
          .and_return(double(count: 4))

        expect(subject).to eq(4)
      end
    end

    context 'when a root_ref does not exist' do
      let(:project) { create(:project, :empty_repo) }

      it 'returns the default_count' do
        expect(subject).to eq(42)
      end
    end

    it "handles exceptions by logging them with exception_details and returns the default_count" do
      allow(Gitlab::GitalyClient).to receive(:call).and_call_original
      allow(Gitlab::GitalyClient).to receive(:call).with(anything, :commit_service, :count_commits, anything, anything).and_raise(e = StandardError.new('_message_'))

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(e, caller_info: :identifiable)

      expect(subject).to eq(42)
    end
  end
end
