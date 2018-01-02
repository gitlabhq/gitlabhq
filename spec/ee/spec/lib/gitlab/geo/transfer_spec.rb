require 'spec_helper'

describe Gitlab::Geo::Transfer do
  include ::EE::GeoHelpers

  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }
  set(:lfs_object) { create(:lfs_object, :with_file) }
  let(:url) { primary_node.geo_transfers_url(:lfs, lfs_object.id.to_s) }
  let(:content) { SecureRandom.random_bytes(10) }
  let(:size) { File.stat(lfs_object.file.path).size }

  subject do
    described_class.new(:lfs,
                        lfs_object.id,
                        lfs_object.file.path,
                        { sha256: lfs_object.oid })
  end

  context '#download_from_primary' do
    before do
      stub_current_geo_node(secondary_node)
    end

    it 'when the destination filename is a directory' do
      transfer = described_class.new(:lfs, lfs_object.id, '/tmp', { sha256: lfs_object.id })

      expect(transfer.download_from_primary).to eq(nil)
    end

    it 'when the HTTP response is successful' do
      expect(FileUtils).to receive(:mv).with(anything, lfs_object.file.path).and_call_original
      response = double(success?: true)
      expect(HTTParty).to receive(:get).and_yield(content.to_s).and_return(response)

      expect(subject.download_from_primary).to eq(size)
      stat = File.stat(lfs_object.file.path)
      expect(stat.size).to eq(size)
      expect(stat.mode & 0777).to eq(0666 - File.umask)
      expect(File.binread(lfs_object.file.path)).to eq(content)
    end

    it 'when the HTTP response is unsuccessful' do
      expect(FileUtils).not_to receive(:mv).with(anything, lfs_object.file.path).and_call_original
      response = double(success?: false, code: 404, msg: 'No such file')
      expect(HTTParty).to receive(:get).and_return(response)

      expect(subject.download_from_primary).to eq(-1)
    end

    it 'when Tempfile fails' do
      expect(Tempfile).to receive(:new).and_raise(Errno::ENAMETOOLONG)

      expect(subject.download_from_primary).to eq(nil)
    end
  end
end
