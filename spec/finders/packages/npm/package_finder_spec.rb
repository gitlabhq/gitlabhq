# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Npm::PackageFinder do
  let(:package) { create(:npm_package) }
  let(:project) { package.project }
  let(:package_name) { package.name }

  describe '#execute!' do
    subject { described_class.new(project, package_name).execute }

    it { is_expected.to eq([package]) }

    context 'with unknown package name' do
      let(:package_name) { 'baz' }

      it { is_expected.to be_empty }
    end
  end

  describe '#find_by_version' do
    let(:version) { package.version }

    subject { described_class.new(project, package.name).find_by_version(version) }

    it { is_expected.to eq(package) }

    context 'with unknown version' do
      let(:version) { 'foobar' }

      it { is_expected.to be_nil }
    end
  end
end
