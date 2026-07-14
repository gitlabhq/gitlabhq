# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeZip::ExtractParams do
  let(:target_path) { Dir.mktmpdir("safe-zip") }
  let(:real_target_path) { File.realpath(target_path) }
  let(:params) { described_class.new(directories: directories, files: files, to: target_path) }
  let(:directories) { %w[public folder/with/subfolder] }
  let(:files) { %w[public/index.html public/assets/image.png] }

  after do
    FileUtils.remove_entry_secure(target_path)
  end

  describe '#extract_path' do
    subject { params.extract_path }

    it { is_expected.to eq(real_target_path) }
  end

  describe '#matching_target_directory' do
    using RSpec::Parameterized::TableSyntax

    subject { params.matching_target_directory(real_target_path + path) }

    where(:path, :result) do
      '/public/index.html' | '/public/'
      '/non/existing/path' | nil
      '/public' | nil
      '/folder/with/index.html' | nil
    end

    with_them do
      it { is_expected.to eq(result ? real_target_path + result : nil) }
    end
  end

  describe '#target_directories' do
    subject { params.target_directories }

    it 'starts with target_path' do
      is_expected.to all(start_with(real_target_path + '/'))
    end

    it 'ends with / for all paths' do
      is_expected.to all(end_with('/'))
    end
  end

  describe '#directories_wildcard' do
    subject { params.directories_wildcard }

    it 'adds * for all paths' do
      is_expected.to all(end_with('/*'))
    end
  end

  describe '#matching_target_file' do
    using RSpec::Parameterized::TableSyntax

    subject { params.matching_target_file(real_target_path + path) }

    where(:path, :result) do
      '/public/index.html' | true
      '/non/existing/path' | false
      '/public/' | false
      '/folder/with/index.html' | false
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  context 'when directories and files are empty' do
    it 'is invalid' do
      expect { described_class.new(to: target_path) }.to raise_error(ArgumentError, /directories or files are required/)
    end
  end
end
