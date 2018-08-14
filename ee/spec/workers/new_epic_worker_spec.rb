# frozen_string_literal: true

require 'spec_helper'

describe NewEpicWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when an epic not found' do
      it 'does not call Services' do
        expect(NotificationService).not_to receive(:new)

        worker.perform(99, create(:user).id)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('NewEpicWorker: couldn\'t find Epic with ID=99, skipping job')

        worker.perform(99, create(:user).id)
      end
    end

    context 'when a user not found' do
      it 'does not call Services' do
        expect(NotificationService).not_to receive(:new)

        worker.perform(create(:epic).id, 99)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('NewEpicWorker: couldn\'t find User with ID=99, skipping job')

        worker.perform(create(:epic).id, 99)
      end
    end

    context 'when everything is ok' do
      let(:user) { create(:user) }
      let(:epic) { create(:epic) }

      before do
        stub_licensed_features(epics: true)
      end

      context 'user watches group' do
        before do
          create(
            :notification_setting,
            user: user,
            source: epic.group,
            level: NotificationSetting.levels[:watch]
          )
        end

        it 'creates a notification for watcher' do
          expect(Notify).to receive(:new_epic_email).with(user.id, epic.id, nil)
            .and_return(double(deliver_later: true))

          worker.perform(epic.id, user.id)
        end
      end

      context 'mention' do
        let(:epic) { create(:epic, description: "epic for #{user.to_reference}") }

        it 'creates a notification for the mentioned user' do
          expect(Notify).to receive(:new_epic_email).with(user.id, epic.id, NotificationReason::MENTIONED)
            .and_return(double(deliver_later: true))

          worker.perform(epic.id, user.id)
        end
      end
    end
  end
end
