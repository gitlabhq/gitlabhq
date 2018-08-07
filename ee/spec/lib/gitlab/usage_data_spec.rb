# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData do
  let(:projects) { create_list(:project, 3) }
  let!(:board) { create(:board, project: projects[0]) }

  describe '#data' do
    before do
      pipeline = create(:ci_pipeline, project: projects[0])
      create(:ci_build, name: 'container_scanning', pipeline: pipeline)
      create(:ci_build, name: 'dast', pipeline: pipeline)
      create(:ci_build, name: 'dependency_scanning', pipeline: pipeline)
      create(:ci_build, name: 'license_management', pipeline: pipeline)
      create(:ci_build, name: 'sast', pipeline: pipeline)
    end

    subject { described_class.data }

    it "gathers usage data" do
      expect(subject.keys).to include(*%i(
        historical_max_users
        license_add_ons
        license_plan
        license_expires_at
        license_starts_at
        license_user_count
        license_trial
        licensee
        license_md5
        license_id
        elasticsearch_enabled
        geo_enabled
      ))
    end

    it "gathers usage counts" do
      count_data = subject[:counts]

      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(3)

      expect(count_data.keys).to include(*%i(
        projects_mirrored_with_pipelines_enabled
        epics
        geo_nodes
        ldap_group_links
        ldap_keys
        ldap_users
        projects_reporting_ci_cd_back_to_github
        container_scanning_jobs
        dast_jobs
        dependency_scanning_jobs
        license_management_jobs
        sast_jobs
      ))
    end

    it 'gathers security products usage data' do
      count_data = subject[:counts]

      expect(count_data[:container_scanning_jobs]).to eq(1)
      expect(count_data[:dast_jobs]).to eq(1)
      expect(count_data[:dependency_scanning_jobs]).to eq(1)
      expect(count_data[:license_management_jobs]).to eq(1)
      expect(count_data[:sast_jobs]).to eq(1)
    end
  end

  describe '#features_usage_data_ee' do
    subject { described_class.features_usage_data_ee }

    it 'gathers feature usage data of EE' do
      expect(subject[:elasticsearch_enabled]).to eq(Gitlab::CurrentSettings.elasticsearch_search?)
      expect(subject[:geo_enabled]).to eq(Gitlab::Geo.enabled?)
    end
  end

  describe 'License edition names' do
    let(:ultimate) { create(:license, plan: 'ultimate') }
    let(:premium) { create(:license, plan: 'premium') }
    let(:starter) { create(:license, plan: 'starter') }
    let(:old) { create(:license, plan: 'other') }

    it "have expected values" do
      expect(ultimate.edition).to eq('EEU')
      expect(premium.edition).to eq('EEP')
      expect(starter.edition).to eq('EES')
      expect(old.edition).to eq('EE')
    end
  end

  describe '#license_usage_data' do
    subject { described_class.license_usage_data }

    it "gathers license data" do
      license = ::License.current

      expect(subject[:license_md5]).to eq(Digest::MD5.hexdigest(license.data))
      expect(subject[:license_id]).to eq(license.license_id)
      expect(subject[:historical_max_users]).to eq(::HistoricalData.max_historical_user_count)
      expect(subject[:licensee]).to eq(license.licensee)
      expect(subject[:license_user_count]).to eq(license.restricted_user_count)
      expect(subject[:license_starts_at]).to eq(license.starts_at)
      expect(subject[:license_expires_at]).to eq(license.expires_at)
      expect(subject[:license_add_ons]).to eq(license.add_ons)
      expect(subject[:license_trial]).to eq(license.trial?)
    end
  end

  describe '.service_desk_counts' do
    subject { described_class.service_desk_counts }

    before do
      Project.update_all(service_desk_enabled: true)
    end

    context 'when Service Desk is disabled' do
      it 'returns an empty hash' do
        stub_licensed_features(service_desk: false)

        expect(subject).to eq({})
      end
    end

    context 'when there is no license' do
      it 'returns an empty hash' do
        allow(License).to receive(:current).and_return(nil)

        expect(subject).to eq({})
      end
    end

    context 'when Service Desk is enabled' do
      it 'gathers Service Desk data' do
        create_list(:issue, 3, confidential: true, author: User.support_bot, project: projects[0])

        stub_licensed_features(service_desk: true)
        allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).with(anything).and_return(true)

        expect(subject).to eq(service_desk_enabled_projects: 3,
                              service_desk_issues: 3)
      end
    end
  end
end
