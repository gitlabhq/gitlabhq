# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::ResetChecksumEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :reset_checksum_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:reset_checksum_event) { event_log.reset_checksum_event }
  let(:project) { reset_checksum_event.project }

  subject { described_class.new(reset_checksum_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    context 'when a tracking entry does not exist' do
      it 'does not create a tracking entry' do
        expect { subject.process }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'logs an info event' do
        data = {
          class: described_class.name,
          message: 'Reset checksum',
          project_id: project.id,
          skippable: true
        }

        expect(::Gitlab::Logger)
          .to receive(:info)
          .with(hash_including(data))

        subject.process
      end
    end

    context 'when a tracking entry exists' do
      let!(:registry) { create(:geo_project_registry, :repository_verified, :wiki_verified, project: project) }

      it 'resets repository/wiki verification state' do
        subject.process

        expect(registry.reload).to have_attributes(
          repository_verification_checksum_sha: nil,
          wiki_verification_checksum_sha: nil
        )
      end

      it 'logs an info event' do
        data = {
          class: described_class.name,
          message: 'Reset checksum',
          project_id: project.id,
          skippable: false
        }

        expect(::Gitlab::Logger)
          .to receive(:info)
          .with(hash_including(data))

        subject.process
      end
    end
  end
end
