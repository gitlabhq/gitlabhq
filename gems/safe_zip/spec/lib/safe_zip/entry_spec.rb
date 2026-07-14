# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeZip::Entry do
  let(:target_path) { Dir.mktmpdir('safe-zip') }
  let(:directories) { %w[public folder/with/subfolder] }
  let(:files) { %w[public/index.html public/assets/image.png] }
  let(:params) { SafeZip::ExtractParams.new(directories: directories, files: files, to: target_path) }

  let(:entry) { described_class.new(zip_archive, zip_entry, params) }
  let(:entry_name) { 'public/folder/index.html' }
  let(:entry_path_dir) { File.join(target_path, File.dirname(entry_name)) }
  let(:entry_path) { File.join(File.realpath(target_path), entry_name) }
  let(:zip_archive) { double }

  let(:zip_entry) do
    double(
      name: entry_name,
      file?: false,
      directory?: false,
      symlink?: false)
  end

  after do
    FileUtils.remove_entry_secure(target_path)
  end

  describe '#path_dir' do
    subject { entry.path_dir }

    it { is_expected.to eq(File.realpath(target_path) + '/public/folder') }
  end

  describe '#exist?' do
    subject { entry.exist? }

    context 'when entry does not exist' do
      it { is_expected.not_to be_truthy }
    end

    context 'when entry does exist' do
      before do
        create_entry
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#extract' do
    subject { entry.extract }

    context 'when entry does not match the filtered directories' do
      let(:directories) { %w[public folder/with/subfolder] }
      let(:files) { [] }

      using RSpec::Parameterized::TableSyntax

      where(:entry_name) do
        [
          'assets/folder/index.html',
          'public/../folder/index.html',
          'public/../../../../../index.html',
          '../../../../../public/index.html',
          '/etc/passwd'
        ]
      end

      with_them do
        it 'does not extract file' do
          is_expected.to be_falsey
        end
      end
    end

    context 'when entry does not match the filtered files' do
      let(:directories) { [] }
      let(:files) { %w[public/index.html public/assets/image.png] }

      using RSpec::Parameterized::TableSyntax

      where(:entry_name) do
        [
          'assets/folder/index.html',
          'public/../folder/index.html',
          'public/../../../../../index.html',
          '../../../../../public/index.html',
          '/etc/passwd'
        ]
      end

      with_them do
        it 'does not extract file' do
          is_expected.to be_falsey
        end
      end
    end

    context 'when there is an existing extracted entry' do
      before do
        create_entry
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(SafeZip::Extract::AlreadyExistsError)
      end
    end

    context 'when entry type is unknown' do
      it 'raises an exception' do
        expect { subject }.to raise_error(SafeZip::Extract::UnsupportedEntryError)
      end
    end

    context 'when entry is valid' do
      shared_examples 'secured symlinks' do
        context 'when we try to extract entry into symlinked folder' do
          before do
            FileUtils.mkdir_p(File.join(target_path, "source"))
            File.symlink("source", File.join(target_path, "public"))
          end

          it 'raises an exception' do
            expect { subject }.to raise_error(SafeZip::Extract::PermissionDeniedError)
          end
        end
      end

      context 'and is file' do
        before do
          allow(zip_entry).to receive(:file?) { true }
        end

        it 'does extract file' do
          expect(zip_archive).to receive(:extract)
            .with(zip_entry, entry_path)
            .and_return(true)

          is_expected.to be_truthy
        end

        it_behaves_like 'secured symlinks'
      end

      context 'and is directory' do
        let(:entry_name) { 'public/folder/assets' }

        before do
          allow(zip_entry).to receive(:directory?) { true }
        end

        it 'does create directory' do
          is_expected.to be_truthy

          expect(File.exist?(entry_path)).to eq(true)
        end

        it_behaves_like 'secured symlinks'
      end

      context 'and is symlink' do
        let(:entry_name) { 'public/folder/assets' }

        before do
          allow(zip_entry).to receive(:symlink?) { true }
          allow(zip_archive).to receive(:read).with(zip_entry) { entry_symlink }
        end

        shared_examples 'a valid symlink' do
          it 'does create symlink' do
            is_expected.to be_truthy

            expect(File.exist?(entry_path)).to eq(true)
          end
        end

        context 'when source is within target' do
          let(:entry_symlink) { '../images' }

          context 'but does not exist' do
            it 'raises an exception' do
              expect { subject }.to raise_error(SafeZip::Extract::SymlinkSourceDoesNotExistError)
            end
          end

          context 'and does exist' do
            before do
              FileUtils.mkdir_p(File.join(target_path, 'public', 'images'))
            end

            it_behaves_like 'a valid symlink'
          end
        end

        context 'when source points outside of target' do
          let(:entry_symlink) { '../../images' }

          before do
            FileUtils.mkdir(File.join(target_path, 'images'))
          end

          it 'raises an exception' do
            expect { subject }.to raise_error(SafeZip::Extract::PermissionDeniedError)
          end
        end

        context 'when source points to /etc/passwd' do
          let(:entry_symlink) { '/etc/passwd' }

          it 'raises an exception' do
            expect { subject }.to raise_error(SafeZip::Extract::PermissionDeniedError)
          end
        end
      end
    end
  end

  private

  def create_entry
    FileUtils.mkdir_p(entry_path_dir)
    FileUtils.touch(entry_path)
  end
end
