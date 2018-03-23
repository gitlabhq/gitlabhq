require 'spec_helper'

RSpec.describe Geo::DeletedProject, type: :model do
  include StubConfiguration

  before do
    storages = {
      'foo' => { 'path' => 'tmp/tests/storage_foo' },
      'bar' => { 'path' => 'tmp/tests/storage_bar' }
    }

    stub_storage_settings(storages)
  end

  subject { described_class.new(id: 1, name: 'sample', disk_path: 'root/sample', repository_storage: 'foo') }

  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:disk_path) }

  describe '#full_path' do
    it 'is an alias for disk_path' do
      expect(subject.full_path).to eq 'root/sample'
    end
  end

  describe '#repository' do
    it 'returns a valid repository' do
      expect(subject.repository).to be_kind_of(Repository)
      expect(subject.repository.disk_path).to eq('root/sample')
    end
  end

  describe '#repository_storage' do
    it 'returns the initialized value when set' do
      expect(subject.repository_storage).to eq 'foo'
    end

    it 'picks storage from ApplicationSetting when value is not initialized' do
      allow_any_instance_of(ApplicationSetting).to receive(:pick_repository_storage).and_return('bar')

      subject = described_class.new(id: 1, name: 'sample', disk_path: 'root/sample', repository_storage: nil)

      expect(subject.repository_storage).to eq('bar')
    end
  end

  describe '#repository_storage_path' do
    it 'returns the repository storage path' do
      expect(subject.repository_storage_path).to eq(File.absolute_path('tmp/tests/storage_foo'))
    end
  end

  describe '#wiki' do
    it 'returns a valid wiki repository' do
      expect(subject.wiki).to be_kind_of(ProjectWiki)
      expect(subject.wiki.disk_path).to eq('root/sample.wiki')
    end
  end

  describe '#wiki_path' do
    it 'returns the wiki repository path on disk' do
      expect(subject.wiki_path).to eq('root/sample.wiki')
    end
  end

  describe '#run_after_commit' do
    it 'runs the given block changing self to the caller' do
      expect(subject).to receive(:repository_storage_path).once

      subject.run_after_commit { self.repository_storage_path }
    end
  end
end
