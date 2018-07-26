require 'rails_helper'

describe Clusters::Applications::Prometheus do
  describe 'transition to updating' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    subject { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    it 'sets last_update_started_at to now' do
      Timecop.freeze do
        expect { subject.make_updating }.to change { subject.reload.last_update_started_at }.to be_within(1.second).of(Time.now)
      end
    end
  end

  describe '#ready' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    it 'returns true when updating' do
      application = build(:clusters_applications_prometheus, :updating, cluster: cluster)

      expect(application).to be_ready
    end

    it 'returns true when updated' do
      application = build(:clusters_applications_prometheus, :updated, cluster: cluster)

      expect(application).to be_ready
    end

    it 'returns true when errored' do
      application = build(:clusters_applications_prometheus, :update_errored, cluster: cluster)

      expect(application).to be_ready
    end
  end

  context '#updated_since?' do
    let(:cluster) { create(:cluster) }
    let(:prometheus_app) { build(:clusters_applications_prometheus, cluster: cluster) }
    let(:timestamp) { Time.now - 5.minutes }

    around do |example|
      Timecop.freeze { example.run }
    end

    before do
      prometheus_app.last_update_started_at = Time.now
    end

    context 'when app does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(prometheus_app.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(prometheus_app.updated_since?(Time.now + 5.minutes)).to be false
      end
    end

    context 'when app has status failed' do
      it 'returns false when last update started after the timestamp' do
        prometheus_app.status = 6

        expect(prometheus_app.updated_since?(timestamp)).to be false
      end
    end
  end

  describe '#update_in_progress?' do
    context 'when app is updating' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = build(:clusters_applications_prometheus, :updating, cluster: cluster)

        expect(prometheus_app.update_in_progress?).to be true
      end
    end
  end

  describe '#update_errored?' do
    context 'when app errored' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = build(:clusters_applications_prometheus, :update_errored, cluster: cluster)

        expect(prometheus_app.update_errored?).to be true
      end
    end
  end

  describe '#get_command' do
    let(:prometheus) { build(:clusters_applications_prometheus) }

    it 'returns an instance of Gitlab::Kubernetes::Helm::GetCommand' do
      expect(prometheus.get_command).to be_an_instance_of(::Gitlab::Kubernetes::Helm::GetCommand)
    end

    it 'should be initialized with 1 argument' do
      command = prometheus.get_command

      expect(command.name).to eq('prometheus')
    end
  end

  describe '#upgrade_command' do
    let(:prometheus) { build(:clusters_applications_prometheus) }
    let(:values) { { foo: 'bar' } }

    it 'returns an instance of Gitlab::Kubernetes::Helm::GetCommand' do
      expect(prometheus.upgrade_command(values)).to be_an_instance_of(::Gitlab::Kubernetes::Helm::UpgradeCommand)
    end

    it 'should be initialized with 3 arguments' do
      command = prometheus.upgrade_command(values)

      expect(command.name).to eq('prometheus')
      expect(command.chart).to eq('stable/prometheus')
      expect(command.values).to eq(values)
    end
  end
end
