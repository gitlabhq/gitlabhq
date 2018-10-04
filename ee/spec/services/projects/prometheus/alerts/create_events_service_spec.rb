# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::CreateEventsService do
  let(:user) { create(:user) }
  set(:project) { create(:project) }
  let(:metric) { create(:prometheus_metric, project: project) }
  let(:service) { described_class.new(project, user, alerts_payload) }

  shared_examples 'events persisted' do |expected_count|
    subject { service.execute }

    it 'returns proper amount of created events' do
      expect(subject.size).to eq(expected_count)
    end

    it 'increments event count' do
      expect { subject }.to change { PrometheusAlertEvent.count }.to(expected_count)
    end
  end

  shared_examples 'no events persisted' do
    subject { service.execute }

    it 'returns no created events' do
      expect(subject).to be_empty
    end

    it 'does not change event count' do
      expect { subject }.not_to change { PrometheusAlertEvent.count }
    end
  end

  context 'with valid alerts_payload' do
    let!(:alert) { create(:prometheus_alert, prometheus_metric: metric, project: project) }

    let(:events) { service.execute }

    context 'with a firing payload' do
      let(:started_at) { truncate_to_second(Time.now) }
      let(:firing_event) { alert_payload(status: 'firing', started_at: started_at) }
      let(:alerts_payload) { { 'alerts' => [firing_event] } }

      it_behaves_like 'events persisted', 1

      it 'returns created event' do
        event = events.first

        expect(event).to be_firing
        expect(event.started_at).to eq(started_at)
        expect(event.ended_at).to be_nil
      end

      context 'with 2 different firing events' do
        let(:another_firing_event) { alert_payload(status: 'firing', started_at: started_at + 1) }
        let(:alerts_payload) { { 'alerts' => [firing_event, another_firing_event] } }

        it_behaves_like 'events persisted', 2
      end

      context 'with already persisted firing event' do
        before do
          service.execute
        end

        it_behaves_like 'no events persisted'
      end

      context 'with duplicate payload' do
        let(:alerts_payload) { { 'alerts' => [firing_event, firing_event] } }

        it_behaves_like 'events persisted', 1
      end
    end

    context 'with a resolved payload' do
      let(:started_at) { truncate_to_second(Time.now) }
      let(:ended_at) { started_at + 1 }
      let(:payload_key) { PrometheusAlertEvent.payload_key_for(alert.prometheus_metric_id, utc_rfc3339(started_at)) }
      let(:resolved_event) { alert_payload(status: 'resolved', started_at: started_at, ended_at: ended_at) }
      let(:alerts_payload) { { 'alerts' => [resolved_event] } }

      context 'with a matching firing event' do
        before do
          create(:prometheus_alert_event,
                 prometheus_alert: alert,
                 payload_key: payload_key,
                 started_at: started_at)
        end

        it 'it does not create an additional event' do
          expect { service.execute }.not_to change { PrometheusAlertEvent.count }
        end

        it 'marks firing event as `resolved`' do
          expect(events.size).to eq(1)

          event = events.first
          expect(event).to be_resolved
          expect(event.started_at).to eq(started_at)
          expect(event.ended_at).to eq(ended_at)
        end

        context 'with duplicate payload' do
          let(:alerts_payload) { { 'alerts' => [resolved_event, resolved_event] } }

          it 'it does not create an additional event' do
            expect { service.execute }.not_to change { PrometheusAlertEvent.count }
          end

          it 'marks firing event as `resolved` only once' do
            expect(events.size).to eq(1)
          end
        end
      end

      context 'without a matching firing event' do
        context 'due to payload_key' do
          let(:payload_key) { 'some other payload_key' }

          before do
            create(:prometheus_alert_event,
                   prometheus_alert: alert,
                   payload_key: payload_key,
                   started_at: started_at)
          end

          it_behaves_like 'no events persisted'
        end

        context 'due to status' do
          before do
            create(:prometheus_alert_event, :resolved,
                   prometheus_alert: alert,
                   started_at: started_at)
          end

          it_behaves_like 'no events persisted'
        end
      end

      context 'with already resolved event' do
        before do
          service.execute
        end

        it_behaves_like 'no events persisted'
      end
    end

    context 'with a metric from another project' do
      let(:another_project) { create(:project) }
      let(:metric) { create(:prometheus_metric, project: another_project) }
      let(:alerts_payload) { { 'alerts' => [alert_payload] } }

      let!(:alert) do
        create(:prometheus_alert,
               prometheus_metric: metric,
               project: another_project)
      end

      it_behaves_like 'no events persisted'
    end
  end

  context 'with invalid payload' do
    let(:alert) { create(:prometheus_alert, prometheus_metric: metric, project: project) }

    describe '`alerts` key' do
      context 'is missing' do
        let(:alerts_payload) { {} }

        it_behaves_like 'no events persisted'
      end

      context 'is nil' do
        let(:alerts_payload) { { 'alerts' => nil } }

        it_behaves_like 'no events persisted'
      end

      context 'is empty' do
        let(:alerts_payload) { { 'alerts' => [] } }

        it_behaves_like 'no events persisted'
      end

      context 'is not a Hash' do
        let(:alerts_payload) { { 'alerts' => [:not_a_hash] } }

        it_behaves_like 'no events persisted'
      end

      describe '`status`' do
        context 'is missing' do
          let(:alerts_payload) { { 'alerts' => [alert_payload(status: nil)] } }

          it_behaves_like 'no events persisted'
        end

        context 'is invalid' do
          let(:alerts_payload) { { 'alerts' => [alert_payload(status: 'invalid')] } }

          it_behaves_like 'no events persisted'
        end
      end

      describe '`started_at`' do
        context 'is missing' do
          let(:alerts_payload) { { 'alerts' => [alert_payload(started_at: nil)] } }

          it_behaves_like 'no events persisted'
        end

        context 'is invalid' do
          let(:alerts_payload) { { 'alerts' => [alert_payload(started_at: 'invalid date')] } }

          it_behaves_like 'no events persisted'
        end
      end

      describe '`ended_at`' do
        context 'is missing' do
          let(:alerts_payload) { { 'alerts' => [alert_payload(ended_at: nil)] } }

          it_behaves_like 'no events persisted'
        end

        context 'is invalid' do
          let(:alerts_payload) { { 'alerts' => [alert_payload(ended_at: 'invalid date')] } }

          it_behaves_like 'no events persisted'
        end
      end

      describe '`labels`' do
        describe '`gitlab_alert_id`' do
          context 'is missing' do
            let(:alerts_payload) { { 'alerts' => [alert_payload(gitlab_alert_id: nil)] } }

            it_behaves_like 'no events persisted'
          end

          context 'is invalid' do
            let(:alerts_payload) { { 'alerts' => [alert_payload(gitlab_alert_id: '-1')] } }

            it_behaves_like 'no events persisted'
          end
        end
      end
    end
  end

  private

  def alert_payload(status: 'firing', started_at: Time.now, ended_at: Time.now, gitlab_alert_id: alert.prometheus_metric_id)
    payload = {}

    payload['status'] = status if status
    payload['startsAt'] = utc_rfc3339(started_at) if started_at
    payload['endsAt'] = utc_rfc3339(ended_at) if ended_at
    payload['labels'] = { 'gitlab_alert_id' => gitlab_alert_id.to_s } if gitlab_alert_id

    payload
  end

  # Example: 2018-09-27T18:25:31.079079416Z
  def utc_rfc3339(date)
    date.utc.strftime("%FT%T.%9NZ")
  rescue
    date
  end

  def truncate_to_second(date)
    date.change(usec: 0)
  end
end
