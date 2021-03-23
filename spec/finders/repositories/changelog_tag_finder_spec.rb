# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ChangelogTagFinder do
  let(:project) { build_stubbed(:project) }
  let(:finder) { described_class.new(project) }

  describe '#execute' do
    context 'when the regular expression is invalid' do
      it 'raises Gitlab::Changelog::Error' do
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
