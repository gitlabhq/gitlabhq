# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Utils::Tar do
  subject(:tar) { described_class.new }

  def tar_tempdir
    Dir.mktmpdir('tar-test') { |dir| yield Pathname(dir) }
  end

  describe '#version' do
    it 'returns a tar version' do
      expect(tar.version).to match(/tar \(GNU tar\) \d+\.\d+/)
    end
  end

  describe '#pack_cmd' do
    it 'instantiate a Shell::Command with default required params' do
      tar_tempdir do |tempdir|
        archive_file = tempdir.join('testarchive.tar')
        target_basepath = tempdir
        target = tempdir.join('*')

        expect do
          tar.pack_cmd(archive_file: archive_file, target_directory: target_basepath, target: target)
        end.not_to raise_exception
      end
    end

    it 'assigns required params to tar option flags' do
      tar_tempdir do |tempdir|
        archive_file = tempdir.join('testarchive.tar')
        target_basepath = tempdir
        target = tempdir.join('*')

        cmd = tar.pack_cmd(archive_file: archive_file, target_directory: target_basepath, target: target)

        expect(cmd.cmd_args).to include("--file=#{archive_file}")
        expect(cmd.cmd_args).to include("--directory=#{target_basepath}")
        expect(cmd.cmd_args.last).to eq(target.to_s)
      end
    end

    it 'accepts multiple targets' do
      tar_tempdir do |tempdir|
        archive_file = tempdir.join('testarchive.tar')
        target_basepath = tempdir
        targets = [tempdir.join('*.txt'), tempdir.join('*.md')]

        cmd = tar.pack_cmd(archive_file: archive_file, target_directory: target_basepath, target: targets)

        expect(cmd.cmd_args).to include("--file=#{archive_file}")
        expect(cmd.cmd_args).to include("--directory=#{target_basepath}")
        expect(cmd.cmd_args.last(2)).to eq(targets.map(&:to_s))
      end
    end

    context 'with excludes' do
      it 'assigns default excludes via tar option flags' do
        tar_tempdir do |tempdir|
          archive_file = tempdir.join('testarchive.tar')
          target_basepath = tempdir
          target = tempdir.join('*')

          cmd = tar.pack_cmd(archive_file: archive_file, target_directory: target_basepath, target: target)

          expect(cmd.cmd_args).to include("--exclude=lost+found")
        end
      end

      it 'assigns provided excludes via tar option flags' do
        tar_tempdir do |tempdir|
          archive_file = tempdir.join('testarchive.tar')
          target_basepath = tempdir
          target = tempdir.join('*')
          excludes = %w[@pages.tmp ignorethis]

          cmd = tar.pack_cmd(archive_file: archive_file, target_directory: target_basepath,
            target: target, excludes: excludes)

          expect(cmd.cmd_args).to include("--exclude=./@pages.tmp")
          expect(cmd.cmd_args).to include("--exclude=./ignorethis")
        end
      end
    end
  end
end
