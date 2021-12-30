# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::PackageFinder do
  include_context 'basic Go module'

  let_it_be(:mod) { create :go_module, project: project }
  let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.1' }
  let_it_be_with_refind(:package) { create :golang_package, project: project, name: mod.name, version: 'v1.0.1' }

  let(:finder) { described_class.new(project, mod_name, version_name) }

  describe '#exists?' do
    subject { finder.exists? }

    context 'with a valid name and version' do
      let(:mod_name) { mod.name }
      let(:version_name) { version.name }

      it 'executes SELECT 1' do
        expect { subject }.to exceed_query_limit(0).for_query(/^SELECT 1/)
      end

      it { is_expected.to eq(true) }
    end

    context 'with an invalid name' do
      let(:mod_name) { 'foo/bar' }
      let(:version_name) { 'baz' }

      it { is_expected.to eq(false) }
    end

    context 'with an invalid version' do
      let(:mod_name) { mod.name }
      let(:version_name) { 'baz' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#execute' do
    subject { finder.execute }

    context 'with a valid name and version' do
      let(:mod_name) { mod.name }
      let(:version_name) { version.name }

      it 'executes a single query' do
        expect { subject }.not_to exceed_query_limit(1)
      end

      it { is_expected.to eq(package) }
    end

    context 'with an uninstallable package' do
      let(:mod_name) { mod.name }
      let(:version_name) { version.name }

      before do
        package.update_column(:status, :error)
      end

      it { is_expected.to eq(nil) }
    end

    context 'with an invalid name' do
      let(:mod_name) { 'foo/bar' }
      let(:version_name) { 'baz' }

      it { is_expected.to eq(nil) }
    end

    context 'with an invalid version' do
      let(:mod_name) { mod.name }
      let(:version_name) { 'baz' }

      it { is_expected.to eq(nil) }
    end
  end
end
