# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::TagsFinder do
  let(:package) { create(:npm_package) }
  let(:project) { package.project }
  let!(:tag1) { create(:packages_tag, package: package) }
  let!(:tag2) { create(:packages_tag, package: package) }
  let(:package_name) { package.name }
  let(:params) { {} }

  describe '#execute' do
    subject { described_class.new(project, package_name, params).execute }

    it { is_expected.to match_array([tag1, tag2]) }

    context 'with package type' do
      let(:package_maven) { create(:maven_package, project: project) }
      let!(:tag_maven) { create(:packages_tag, package: package_maven) }
      let(:package_name) { package_maven.name }
      let(:params) { { package_type: package_maven.package_type } }

      it { is_expected.to match_array([tag_maven]) }
    end

    context 'with blank package type' do
      let(:params) { { package_type: '   ' } }

      it { is_expected.to match_array([tag1, tag2]) }
    end

    context 'with nil package type' do
      let(:params) { { package_type: nil } }

      it { is_expected.to match_array([tag1, tag2]) }
    end

    context 'with unknown package name' do
      let(:package_name) { 'foobar' }

      it { is_expected.to be_empty }
    end
  end

  describe '#find_by_name' do
    let(:tag_name) { tag1.name }

    subject { described_class.new(project, package_name, params).execute.find_by_name(tag_name) }

    it { is_expected.to eq(tag1) }

    context 'with package type' do
      let(:package_maven) { create(:maven_package, project: project) }
      let!(:tag_maven) { create(:packages_tag, package: package_maven) }
      let(:package_name) { package_maven.name }
      let(:params) { { package_type: package_maven.package_type } }
      let(:tag_name) { tag_maven.name }

      it { is_expected.to eq(tag_maven) }
    end

    context 'with unknown tag_name' do
      let(:tag_name) { 'foobar' }

      it { is_expected.to be_nil }
    end
  end
end
