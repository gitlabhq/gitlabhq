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

    context 'application install previously errored with older version' do
      subject { create(:clusters_applications_prometheus, :installed, cluster: cluster, version: '6.7.2') }

      it 'updates the application version' do
        subject.make_updating

        expect(subject.reload.version).to eq('6.7.3')
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

  describe '#upgrade_command' do
    let(:prometheus) { build(:clusters_applications_prometheus) }
    let(:values) { prometheus.values }

    it 'returns an instance of Gitlab::Kubernetes::Helm::GetCommand' do
      expect(prometheus.upgrade_command(values)).to be_an_instance_of(::Gitlab::Kubernetes::Helm::UpgradeCommand)
    end

    it 'should be initialized with 3 arguments' do
      command = prometheus.upgrade_command(values)

      expect(command.name).to eq('prometheus')
      expect(command.chart).to eq('stable/prometheus')
      expect(command.version).to eq('6.7.3')
      expect(command.files).to eq(prometheus.files)
    end
  end

  describe '#files_with_replaced_values' do
    let(:application) { build(:clusters_applications_prometheus) }
    let(:files) { application.files }

    subject { application.files_with_replaced_values({ hello: :world }) }

    it 'does not modify #files' do
      expect(subject[:'values.yaml']).not_to eq(files)
      expect(files[:'values.yaml']).to eq(application.values)
    end

    it 'returns values.yaml with replaced values' do
      expect(subject[:'values.yaml']).to eq({ hello: :world })
    end

    it 'should include cert files' do
      expect(subject[:'ca.pem']).to be_present
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      expect(subject[:'cert.pem']).to be_present
      expect(subject[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
    end

    context 'when the helm application does not have a ca_cert' do
      before do
        application.cluster.application_helm.ca_cert = nil
      end

      it 'should not include cert files' do
        expect(subject[:'ca.pem']).not_to be_present
        expect(subject[:'cert.pem']).not_to be_present
        expect(subject[:'key.pem']).not_to be_present
      end
    end
  end
end
