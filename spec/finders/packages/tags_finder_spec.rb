# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TagsFinder, feature_category: :package_registry do
  let_it_be(:package) { create(:npm_package) }
  let_it_be(:project) { package.project }
  let_it_be(:tag1) { create(:packages_tag, package: package) }
  let_it_be(:tag2) { create(:packages_tag, package: package) }
  let_it_be(:package_name) { package.name }
  let_it_be(:package_maven) { create(:maven_package, project: project, name: package_name) }

  let(:params) { {} }

  describe '#execute' do
    let_it_be(:tag_maven) { create(:packages_tag, package: package_maven, name: tag1.name) }

    subject { described_class.new(project, package_name, params).execute }

    it { is_expected.to contain_exactly(tag1, tag2, tag_maven) }

    context 'with package type' do
      let(:params) { { package_type: package_maven.package_type } }

      it { is_expected.to contain_exactly(tag1, tag2, tag_maven) }

      context 'with packages_tags_finder_use_packages_class feature flag disabled' do
        before do
          stub_feature_flags(packages_tags_finder_use_packages_class: false)
        end

        it { is_expected.to contain_exactly(tag_maven) }
      end

      context 'with blank package type' do
        let(:params) { { package_type: '   ' } }

        it { is_expected.to contain_exactly(tag1, tag2, tag_maven) }
      end

      context 'with nil package type' do
        let(:params) { { package_type: nil } }

        it { is_expected.to contain_exactly(tag1, tag2, tag_maven) }
      end
    end

    context 'with unknown package name' do
      let(:package_name) { 'foobar' }

      it { is_expected.to be_empty }
    end

    context 'with packages class' do
      let(:params) { { packages_class: ::Packages::Maven::Package } }

      it { is_expected.to contain_exactly(tag_maven) }

      context 'with packages_tags_finder_use_packages_class feature flag disabled' do
        before do
          stub_feature_flags(packages_tags_finder_use_packages_class: false)
        end

        it { is_expected.to contain_exactly(tag1, tag2, tag_maven) }
      end
    end
  end

  describe '#find_by_name' do
    let_it_be(:tag_name) { tag1.name }

    subject { described_class.new(project, package_name, params).find_by_name(tag_name) }

    it { is_expected.to eq(tag1) }

    context 'with package type' do
      let_it_be(:tag_maven) { create(:packages_tag, package: package_maven) }

      let(:params) { { package_type: :maven } }

      it { is_expected.to eq(tag1) }

      context 'with packages_tags_finder_use_packages_class feature flag disabled' do
        let_it_be(:tag_maven) { create(:packages_tag, package: package_maven, name: tag_name) }

        before do
          stub_feature_flags(packages_tags_finder_use_packages_class: false)
        end

        it { is_expected.to eq(tag_maven) }
      end
    end

    context 'with packages class' do
      let(:params) { { packages_class: ::Packages::Maven::Package } }

      it { is_expected.to be_nil }

      context 'with packages_tags_finder_use_packages_class feature flag disabled' do
        let_it_be(:tag_maven) { create(:packages_tag, package: package_maven) }

        before do
          stub_feature_flags(packages_tags_finder_use_packages_class: false)
        end

        it { is_expected.to eq(tag1) }
      end
    end

    context 'with unknown tag_name' do
      let_it_be(:tag_name) { 'foobar' }

      it { is_expected.to be_nil }
    end
  end
end
