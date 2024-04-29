# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ChangelogTagFinder, feature_category: :source_code_management do
  let(:project) { build_stubbed(:project) }
  let(:finder) { described_class.new(project, regex: regex) }
  let(:regex) { Gitlab::Changelog::Config::DEFAULT_TAG_REGEX }

  describe '#execute' do
    context 'when the regular expression is invalid' do
      it 'raises Gitlab::Changelog::Error' do
        allow(project.repository).to receive(:tags).and_return([double(:tag, name: 'v1.1.0')])

        expect { described_class.new(project, regex: 'foo+*').execute('1.2.3') }
          .to raise_error(Gitlab::Changelog::Error)
      end
    end

    context 'when there is a previous tag' do
      it 'returns the previous tag' do
        tag1 = double(:tag1, name: 'v1.0.0')
        tag2 = double(:tag2, name: 'v1.1.0')
        tag3 = double(:tag3, name: 'v2.0.0')
        tag4 = double(:tag4, name: '0.9.0')
        tag5 = double(:tag5, name: 'v0.8.0-pre1')
        tag6 = double(:tag6, name: 'v0.7.0')
        tag7 = double(:tag7, name: '0.5.0+42.ee.0')

        allow(project.repository)
          .to receive(:tags)
          .and_return([tag1, tag3, tag2, tag4, tag5, tag6, tag7])

        expect(finder.execute('2.1.0')).to eq(tag3)
        expect(finder.execute('2.0.0')).to eq(tag2)
        expect(finder.execute('1.5.0')).to eq(tag2)
        expect(finder.execute('1.0.1')).to eq(tag1)
        expect(finder.execute('1.0.0')).to eq(tag4)
        expect(finder.execute('0.9.0')).to eq(tag6)
        expect(finder.execute('0.6.0')).to eq(tag7)

        # with a pre-release version
        expect(finder.execute('0.6.0-rc1')).to eq(tag7)

        # with v at the beginning
        expect(finder.execute('v2.1.0')).to eq(tag3)
        expect { finder.execute('wrong_version') }.to raise_error(Gitlab::Changelog::Error)
      end
    end

    context 'when GitLab release process' do
      let(:regex) { '^v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)-ee$' }

      let!(:previous_tag) { double(:tag1, name: 'v16.8.0-ee') }
      let!(:rc_tag) { double(:tag2, name: 'v16.9.0-rc42-ee') }

      before do
        allow(project.repository)
          .to receive(:tags)
          .and_return([rc_tag, previous_tag])
      end

      it 'supports GitLab release process' do
        expect(finder.execute('16.9.0')).to eq(previous_tag)
        expect(finder.execute('16.8.0')).to eq(nil)
      end
    end

    context 'when Omnibus release process' do
      let(:regex) { '^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(\+(?P<pre>rc\d+))?((\.|\+)(?P<meta>ee\.\d+))?$' }

      let!(:previous_tag) { double(:tag1, name: '16.8.0+ee.0') }
      let!(:rc_tag) { double(:tag2, name: '16.9.0+rc42.ee.0') }
      let!(:previous_ce_tag) { double(:tag3, name: '16.7.0+ce.0') }

      before do
        allow(project.repository)
          .to receive(:tags)
          .and_return([rc_tag, previous_tag, previous_ce_tag])
      end

      it 'supports Omnibus release process' do
        expect(finder.execute('16.9.0')).to eq(previous_tag)
        expect(finder.execute('16.8.0')).to eq(previous_tag)
        expect(finder.execute('16.7.0')).to eq(nil)
      end
    end

    context 'when Gitaly release process' do
      let!(:previous_tag) { double(:tag1, name: 'v16.8.0') }
      let!(:rc_tag) { double(:tag2, name: 'v16.9.0-rc42') }

      before do
        allow(project.repository)
          .to receive(:tags)
          .and_return([rc_tag, previous_tag])
      end

      it 'supports Gitaly release process' do
        expect(finder.execute('16.9.0')).to eq(previous_tag)
        expect(finder.execute('16.8.0')).to eq(nil)
      end
    end

    context 'when there is no previous tag' do
      it 'returns nil' do
        tag1 = double(:tag1, name: 'v1.0.0')
        tag2 = double(:tag2, name: 'v1.1.0')

        allow(project.repository)
          .to receive(:tags)
          .and_return([tag1, tag2])

        expect(finder.execute('1.0.0')).to be_nil
      end
    end
  end
end
