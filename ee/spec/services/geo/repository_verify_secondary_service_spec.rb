require 'spec_helper'

describe Geo::RepositoryVerifySecondaryService, :geo do
  include ::EE::GeoHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    let(:repository_state) { create(:repository_state, project: create(:project, :repository))}
    let(:registry) do
      registry = create(:geo_project_registry, project: repository_state.project)
      registry.project.last_repository_updated_at = 7.hours.ago
      registry.project.repository_state.last_repository_verification_at = 5.hours.ago
      registry.last_repository_successful_sync_at = 5.hours.ago
      registry.project.repository_state.repository_verification_checksum = 'my_checksum'

      registry
    end
    let(:service)  { described_class.new(registry, :repository) }

    it 'only works on the secondary' do
      stub_current_geo_node(primary)

      expect(service).not_to receive(:log_info)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      allow(service).to receive(:calculate_checksum).and_return('my_checksum')

      expect(service).to receive(:record_status).once.with(checksum: 'my_checksum')

      service.execute
    end

    it 'sets failure message when the checksum does not match' do
      allow(service).to receive(:calculate_checksum).and_return('not_my_checksum')

      expect(service).to receive(:record_status).once.with(error_msg: start_with('Repository checksum mismatch'))

      service.execute
    end
  end

  shared_examples 'should_verify_checksum? for repositories/wikis' do |type|
    let(:repository_state) { create(:repository_state, project: create(:project, :repository))}
    let(:registry) do
      registry = create(:geo_project_registry, project: repository_state.project)
      registry.project.last_repository_updated_at = 7.hours.ago
      registry.project.repository_state.public_send("last_#{type}_verification_at=", 5.hours.ago)
      registry.public_send("last_#{type}_successful_sync_at=", 5.hours.ago)
      registry.project.repository_state.public_send("#{type}_verification_checksum=", 'my_checksum')

      registry
    end
    let(:service)  { described_class.new(registry, type) }

    it 'verifies the repository' do
      expect(service.should_verify_checksum?).to be_truthy
    end

    it 'does not verify if primary was never verified' do
      registry.project.repository_state.public_send("last_#{type}_verification_at=", nil)

      expect(service.should_verify_checksum?).to be_falsy
    end

    it 'does not verify if the checksums already match' do
      registry.project.repository_state.public_send("#{type}_verification_checksum=", 'my_checksum')
      registry.public_send("#{type}_verification_checksum=", 'my_checksum')

      expect(service.should_verify_checksum?).to be_falsy
    end

    it 'does not verify if the primary was verified before the secondary' do
      registry.project.repository_state.public_send("last_#{type}_verification_at=", 50.minutes.ago)
      registry.public_send("last_#{type}_verification_at=", 30.minutes.ago)

      expect(service.should_verify_checksum?).to be_falsy
    end

    it 'does verify if the secondary was never verified' do
      registry.public_send("last_#{type}_verification_at=", nil)

      expect(service.should_verify_checksum?).to be_truthy
    end

    it 'does not verify if never synced' do
      registry.public_send("last_#{type}_successful_sync_at=", nil)

      expect(service.should_verify_checksum?).to be_falsy
    end

    it 'does not verify if the secondary synced before the last secondary verification' do
      registry.public_send("last_#{type}_verification_at=", 50.minutes.ago)
      registry.public_send("last_#{type}_successful_sync_at=", 30.minutes.ago)

      expect(service.should_verify_checksum?).to be_falsy
    end

    it 'has been at least 6 hours since the primary repository was updated' do
      registry.project.last_repository_updated_at = 7.hours.ago

      expect(service.should_verify_checksum?).to be_truthy
    end
  end

  describe '#should_verify_checksum?' do
    context 'repository' do
      include_examples 'should_verify_checksum? for repositories/wikis', :repository
    end

    context 'wiki' do
      include_examples 'should_verify_checksum? for repositories/wikis', :wiki
    end
  end

  shared_examples 'record_status for repositories/wikis' do |type|
    it 'records a successful verification' do
      service.send(:record_status, checksum: 'my_checksum')
      registry.reload

      expect(registry.public_send("#{type}_verification_checksum")).to eq 'my_checksum'
      expect(registry.public_send("last_#{type}_verification_at")).not_to be_nil
      expect(registry.public_send("last_#{type}_verification_failure")).to be_nil
      expect(registry.public_send("last_#{type}_verification_failed")).to be_falsey
    end

    it 'records a failure' do
      service.send(:record_status, error_msg: 'Repository checksum did not match')
      registry.reload

      expect(registry.public_send("#{type}_verification_checksum")).to be_nil
      expect(registry.public_send("last_#{type}_verification_at")).not_to be_nil
      expect(registry.public_send("last_#{type}_verification_failure")).to eq 'Repository checksum did not match'
      expect(registry.public_send("last_#{type}_verification_failed")).to be_truthy
    end
  end

  describe '#record_status' do
    let(:registry) { create(:geo_project_registry) }

    context 'for a repository' do
      let(:service)  { described_class.new(registry, :repository) }

      include_examples 'record_status for repositories/wikis', :repository
    end

    context 'for a wiki' do
      let(:service)  { described_class.new(registry, :wiki) }

      include_examples 'record_status for repositories/wikis', :wiki
    end
  end
end
