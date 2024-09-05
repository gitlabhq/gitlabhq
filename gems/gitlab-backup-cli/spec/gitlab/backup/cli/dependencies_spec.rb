# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Dependencies do
  let(:bin_path) { Dir.mktmpdir('dependencies', temp_path) }

  before do
    stub_env('PATH', bin_path)
  end

  after do
    FileUtils.rmtree(bin_path)
  end

  describe '.find_executable' do
    it 'returns the full path of the executable' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable('dummy')).to eq(executable)
    end

    it 'returns nil when executable cant be found' do
      expect(described_class.find_executable('non-existent')).to be_nil
    end

    it 'also finds by absolute path' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable(executable)).to eq(executable)
    end
  end

  describe '.executable_exist?' do
    it 'returns true if an executable exists in the PATH' do
      create_dummy_executable('dummy')

      expect(described_class.executable_exist?('dummy')).to be_truthy
    end

    it 'returns false when no exectuable can be found' do
      expect(described_class.executable_exist?('non-existent')).to be_falsey
    end
  end

  def create_dummy_executable(name)
    filepath = File.join(bin_path, name)

    FileUtils.touch(filepath)
    File.chmod(0o755, filepath)

    filepath
  end
end
