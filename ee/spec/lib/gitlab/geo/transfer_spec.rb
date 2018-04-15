require 'spec_helper'

describe Gitlab::Geo::Transfer do
  include ::EE::GeoHelpers

  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }
  set(:lfs_object) { create(:lfs_object, :with_file) }
  let(:lfs_object_file_path) { lfs_object.file.path }
  let(:url) { primary_node.geo_transfers_url(:lfs, lfs_object.id.to_s) }
  let(:content) { SecureRandom.random_bytes(10) }
  let(:size) { File.stat(lfs_object.file.path).size }

  subject do
    described_class.new(:lfs,
                        lfs_object.id,
                        lfs_object_file_path,
                        { sha256: lfs_object.oid })
  end

  context '#download_from_primary' do
    before do
      stub_current_geo_node(secondary_node)
    end

    context 'when the destination filename is a directory' do
      it 'returns a failed result' do
        transfer = described_class.new(:lfs, lfs_object.id, '/tmp', { sha256: lfs_object.id })

        result = transfer.download_from_primary

        expect_result(result, success: false, bytes_downloaded: 0, primary_missing_file: false)
      end
    end

    context 'when the HTTP response is successful' do
      it 'returns a successful result' do
        expect(FileUtils).to receive(:mv).with(anything, lfs_object.file.path).and_call_original
        response = double(:response, success?: true)
        expect(Gitlab::HTTP).to receive(:get).and_yield(content.to_s).and_return(response)

        result = subject.download_from_primary

        expect_result(result, success: true, bytes_downloaded: size, primary_missing_file: false)
        stat = File.stat(lfs_object.file.path)
        expect(stat.size).to eq(size)
        expect(stat.mode & 0777).to eq(0666 - File.umask)
        expect(File.binread(lfs_object.file.path)).to eq(content)
      end
    end

    context 'when the HTTP response is unsuccessful' do
      context 'when the HTTP response indicates a missing file on the primary' do
        it 'returns a failed result indicating primary_missing_file' do
          expect(FileUtils).not_to receive(:mv).with(anything, lfs_object.file.path).and_call_original
          response = double(:response, success?: false, code: 404, msg: "No such file")
          expect(File).to receive(:read).and_return("{\"geo_code\":\"#{Gitlab::Geo::FileUploader::FILE_NOT_FOUND_GEO_CODE}\"}")
          expect(Gitlab::HTTP).to receive(:get).and_return(response)

          result = subject.download_from_primary

          expect_result(result, success: false, bytes_downloaded: 0, primary_missing_file: true)
        end
      end

      context 'when the HTTP response does not indicate a missing file on the primary' do
        it 'returns a failed result' do
          expect(FileUtils).not_to receive(:mv).with(anything, lfs_object.file.path).and_call_original
          response = double(:response, success?: false, code: 404, msg: 'No such file')
          expect(Gitlab::HTTP).to receive(:get).and_return(response)

          result = subject.download_from_primary

          expect_result(result, success: false, bytes_downloaded: 0)
        end
      end
    end

    context 'when Tempfile fails' do
      it 'returns a failed result' do
        expect(Tempfile).to receive(:new).and_raise(Errno::ENAMETOOLONG)

        result = subject.download_from_primary

        expect(result.success).to eq(false)
        expect(result.bytes_downloaded).to eq(0)
      end
    end

    context "invalid path" do
      let(:lfs_object_file_path) { '/foo/bar' }

      it 'logs an error if the destination directory could not be created' do
        allow(FileUtils).to receive(:mkdir_p) { raise Errno::EEXIST }

        expect(subject).to receive(:log_error).with("unable to create directory /foo: File exists")
        result = subject.download_from_primary

        expect(result.success).to eq(false)
        expect(result.bytes_downloaded).to eq(0)
      end
    end
  end

  def expect_result(result, success:, bytes_downloaded:, primary_missing_file: nil)
    expect(result.success).to eq(success)
    expect(result.bytes_downloaded).to eq(bytes_downloaded)
    expect(result.primary_missing_file).to eq(primary_missing_file)
  end
end
