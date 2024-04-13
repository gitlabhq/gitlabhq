# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::BackupMetadata do
  subject(:metadata) { build(:backup_metadata) }

  let(:expected_keys) { %i[metadata_version created_at backup_id gitlab_version] }
  let(:tmp_dir) { Pathname(Dir.mktmpdir('backup-metadata', temp_path)) }

  after do
    tmp_dir.rmtree
  end

  describe '#to_hash' do
    let(:metadata_hash) { metadata.to_hash }

    it 'returns a hash with the required keys' do
      expect(metadata_hash.keys).to contain_exactly(*expected_keys)
    end

    it 'created_at data is formatted as iso8601' do
      parsed = Time.iso8601(metadata_hash[:created_at])

      expect(parsed).to eq(metadata.created_at.floor)
    end
  end

  describe '#to_json' do
    it 'returns a json with the required keys' do
      json = metadata.to_json
      parsed_json = JSON.parse(json, symbolize_names: true)

      expect(json).to be_a String
      expect(json).not_to be_empty
      expect(parsed_json.keys).to contain_exactly(*expected_keys)
    end
  end

  describe '#write!' do
    let(:json_file) { tmp_dir.join(described_class::METADATA_FILENAME) }

    it 'creates a file with specific permissions' do
      expect { metadata.write!(tmp_dir) }.to change { json_file.exist? }.from(false).to(true)
      permissions_octal = json_file.lstat.mode % 0o1000
      expect(permissions_octal).to eq(0o600)
    end

    it 'writes metadata information to a file' do
      metadata.write!(tmp_dir)

      json_content = File.read(json_file)
      expect(json_content).not_to be_empty

      parsed_json = JSON.parse(json_content, symbolize_names: true)
      expect(parsed_json.keys).to contain_exactly(*expected_keys)
    end

    context 'when basepath doesnt exist', :silence_output do
      let(:nonexistentpath) { tmp_dir.join('nonexistentfolder') }

      it 'doesnt raise an error' do
        expect { metadata.write!(nonexistentpath) }.not_to raise_error
      end

      it 'outputs an error message to stderr' do
        expect { metadata.write!(nonexistentpath) }.to output(/Failed to Backup information/).to_stderr
      end

      it 'returns false' do
        expect(metadata.write!(nonexistentpath)).to be_falsey
      end
    end
  end
end
