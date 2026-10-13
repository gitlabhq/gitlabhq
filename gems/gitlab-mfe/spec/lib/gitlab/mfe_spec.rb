# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Gitlab::Mfe, feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  describe '.enabled?' do
    subject(:enabled) { described_class.enabled? }

    context 'when the enabled hook is a plain value' do
      where(:value) { [true, false] }

      with_them do
        before do
          described_class.configure { |config| config.enabled = value }
        end

        it { is_expected.to be(value) }
      end
    end

    context 'when the host application injects no hook' do
      it 'defaults to disabled' do
        expect(enabled).to be(false)
      end
    end

    context 'when the enabled hook is a callable' do
      before do
        described_class.configure { |config| config.enabled = -> { true } }
      end

      it { is_expected.to be(true) }
    end

    context 'when the enabled hook returns a truthy non-boolean' do
      before do
        described_class.configure { |config| config.enabled = -> { 'yes' } }
      end

      it { is_expected.to be(true) }
    end

    context 'when the enabled hook returns nil' do
      before do
        described_class.configure { |config| config.enabled = -> {} }
      end

      it { is_expected.to be(false) }
    end
  end

  describe '.registry_url' do
    subject(:registry_url) { described_class.registry_url }

    context 'when a registry url is injected' do
      before do
        described_class.configure do |config|
          config.registry_url = 'https://custom.example.com'
        end
      end

      it { is_expected.to eq('https://custom.example.com') }
    end

    context 'when the registry url is injected as a callable' do
      before do
        described_class.configure do |config|
          config.registry_url = -> { 'https://callable.example.com' }
        end
      end

      it { is_expected.to eq('https://callable.example.com') }
    end

    context 'when no registry url is injected' do
      it { is_expected.to eq(described_class::DEFAULT_REGISTRY_URL) }
    end

    # Contract: a nil registry_url from ANY source falls back to the default.
    # This is the one intentional divergence from the pre-extraction code
    # (which returned nil when the mfe config section existed but carried no
    # registry_url). The characterization harness for #616912 proved every
    # other input is byte-for-byte identical; these cases lock the fallback so
    # a future change cannot silently reintroduce a nil registry_url.
    context 'when the injected registry url resolves to nil' do
      where(:hook) { [nil, -> {}] }

      with_them do
        before do
          described_class.configure { |config| config.registry_url = hook }
        end

        it 'falls back to the default registry url' do
          expect(registry_url).to eq(described_class::DEFAULT_REGISTRY_URL)
        end
      end
    end
  end

  describe 'vendor file memoization' do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      path = write_pin('first.yml', 'first_app')
      described_class.configure { |config| config.vendor_file_path = path }
      described_class::VendorFile.entries
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end

    def write_pin(file_name, app_name)
      File.join(tmpdir, file_name).tap do |path|
        File.write(path, "apps:\n  - name: #{app_name}\n    version: 0.4.0\n    sha: #{'a' * 64}\n")
      end
    end

    it 'reloads the pin file when the vendor file path is reconfigured' do
      path = write_pin('second.yml', 'second_app')

      described_class.configure { |config| config.vendor_file_path = path }

      expect(described_class::VendorFile.entries.map(&:name)).to eq(['second_app'])
    end

    it 'drops the loaded pins on reset_configuration!' do
      described_class.reset_configuration!

      expect { described_class::VendorFile.entries }
        .to raise_error(described_class::VendorFile::InvalidEntryError, /vendor_file_path is not configured/)
    end
  end
end
