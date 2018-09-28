# frozen_string_literal: true

require 'spec_helper'

describe Geo::RepositoryUpdatedEventStore do
  include EE::GeoHelpers

  set(:project)  { create(:project, :repository) }
  set(:secondary_node) { create(:geo_node) }

  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:refs)     { ['refs/heads/tést', 'refs/tags/tag'] }

  let(:changes) do
    [
      { before: '123456', after: '789012', ref: 'refs/heads/tést' },
      { before: '654321', after: '210987', ref: 'refs/tags/tag' }
    ]
  end

  subject { described_class.new(project, refs: refs, changes: changes) }

  describe '#create' do
    it_behaves_like 'a Geo event store', Geo::RepositoryUpdatedEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      context 'when repository is being updated' do
        it 'does not track ref name when post-receive event affect multiple refs' do
          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last.ref).to be_nil
        end

        it 'tracks ref name when post-receive event affect single ref' do
          refs    = ['refs/heads/tést']
          changes = [{ before: '123456', after: blankrev, ref: 'refs/heads/tést' }]
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last.ref).to eq 'refs/heads/tést'
        end

        it 'tracks number of branches post-receive event affects' do
          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last.branches_affected).to eq 1
        end

        it 'tracks number of tags post-receive event affects' do
          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last.tags_affected).to eq 1
        end

        it 'tracks when post-receive event create new branches' do
          refs    = ['refs/heads/tést', 'refs/heads/feature']
          changes = [
            { before: '123456', after: '789012', ref: 'refs/heads/tést' },
            { before: blankrev, after: '210987', ref: 'refs/heads/feature' }
          ]
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last.new_branch).to eq true
        end

        it 'tracks when post-receive event remove branches' do
          refs    = ['refs/heads/tést', 'refs/heads/feature']
          changes = [
            { before: '123456', after: '789012', ref: 'refs/heads/tést' },
            { before: '654321', after: blankrev, ref: 'refs/heads/feature' }
          ]
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last.remove_branch).to eq true
        end
      end

      context 'when wiki is being updated' do
        it 'does not track any information' do
          subject = described_class.new(project, source: Geo::RepositoryUpdatedEvent::WIKI)

          subject.create!

          expect(Geo::RepositoryUpdatedEvent.last).to have_attributes(
            ref: be_nil,
            branches_affected: be_zero,
            tags_affected: be_zero,
            new_branch: false,
            remove_branch: false
          )
        end
      end
    end
  end
end
