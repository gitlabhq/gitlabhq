# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'gitlab/housekeeper/substitutor'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- there are lots of parameters at play
RSpec.describe ::Gitlab::Housekeeper::Substitutor do
  let(:fake_keep) { instance_double(Class) }
  let(:repository_path) { Pathname(Dir.mktmpdir) }

  let(:file_with_no_substitutions) { 'file1.txt' }
  let(:file_with_substitutions) { 'file2.txt' }

  let(:mr_web_url) { 'gitlab.example.com' }
  let(:change) do
    create_change(
      changed_files: [file_with_no_substitutions, file_with_substitutions],
      mr_web_url: mr_web_url
    )
  end

  before do
    fake_keep_instance = instance_double(::Gitlab::Housekeeper::Keep)
    allow(fake_keep).to receive(:new).and_return(fake_keep_instance)

    allow(fake_keep_instance).to receive(:each_change)
      .and_yield(change)

    @previous_dir = Dir.pwd
    Dir.chdir(repository_path)

    File.write(file_with_no_substitutions, "Content of file 1")
    File.write(file_with_substitutions, "Content of file 2 #{described_class::MR_WEB_URL_PLACEHOLDER}")
  end

  after do
    Dir.chdir(@previous_dir) if @previous_dir # rubocop:disable RSpec/InstanceVariable -- let not suitable for before/after cleanup
    FileUtils.rm_rf(repository_path)
  end

  describe '#perform' do
    subject { described_class.perform(change) }

    it 'replaces the placeholder text with the MR web URL' do
      subject

      expect(File.read(file_with_no_substitutions)).to eq('Content of file 1')
      expect(File.read(file_with_substitutions)).to eq('Content of file 2 gitlab.example.com')
    end

    context 'when the MR web URL is not set' do
      before do
        change.mr_web_url = nil
      end

      it do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the file does not exist (it is being removed by the keep)' do
      before do
        change.changed_files = ['removed_file.txt']
      end

      it do
        expect { subject }.not_to raise_error
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
