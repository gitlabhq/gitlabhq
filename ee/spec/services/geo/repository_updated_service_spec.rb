require 'spec_helper'

describe Geo::RepositoryUpdatedService do
  include ::EE::GeoHelpers

  set(:project) { create(:project) }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }
  set(:repository_state) { create(:repository_state, :repository_verified, :wiki_verified, project: project) }

  before do
    stub_current_geo_node(primary)
  end

  describe '#execute' do
    subject { described_class.new(project, source: source) }

    shared_examples 'repository being updated' do
      context 'when not running on a primary node' do
        before do
          allow(Gitlab::Geo).to receive(:primary?) { false }
        end

        it 'does not create a repository updated event' do
          expect { subject.execute }.not_to change(Geo::RepositoryUpdatedEvent, :count)
        end

        it 'does not reset the repository verification checksum' do
          expect { subject.execute }.not_to change(repository_state.reload, "#{method_prefix}_verification_checksum")
        end

        it 'does not reset the repository verification failure' do
          expect { subject.execute }.not_to change(repository_state.reload, "last_#{method_prefix}_verification_failure")
        end
      end

      context 'when running on a primary node' do
        it 'creates a repository updated event' do
          expect { subject.execute }.to change(Geo::RepositoryUpdatedEvent, :count).by(1)
        end

        it 'resets the repository verification checksum' do
          expect { subject.execute }.to change { repository_state.reload.public_send("#{method_prefix}_verification_checksum") }.to(nil)
        end

        it 'resets the repository verification failure' do
          repository_state.update!("last_#{method_prefix}_verification_failure" => 'xxxx')
          expect { subject.execute }.to change { repository_state.reload.public_send("last_#{method_prefix}_verification_failure") }.to(nil)
        end

        it 'does not raise an error when project have never been verified' do
          expect { described_class.new(create(:project)) }.not_to raise_error
        end

        it 'raises a Geo::RepositoryUpdatedService::RepositoryUpdateError when an error occurs' do
          allow(subject.repository_state).to receive(:update!)
            .with("#{method_prefix}_verification_checksum" => nil, "last_#{method_prefix}_verification_failure" => nil)
            .and_raise(ActiveRecord::RecordInvalid.new(repository_state))

          expect { subject.execute }.to raise_error Geo::RepositoryUpdatedService::RepositoryUpdateError, /Cannot reset repository checksum/
        end
      end
    end

    context 'when repository is being updated' do
      include_examples 'repository being updated' do
        let(:source) { Geo::RepositoryUpdatedEvent::REPOSITORY }
        let(:method_prefix) { 'repository' }
      end
    end

    context 'when wiki is being updated' do
      include_examples 'repository being updated' do
        let(:source) { Geo::RepositoryUpdatedEvent::WIKI }
        let(:method_prefix) { 'wiki' }
      end
    end
  end
end
