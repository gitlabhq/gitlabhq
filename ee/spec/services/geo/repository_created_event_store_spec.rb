# frozen_string_literal: true

require 'spec_helper'

describe Geo::RepositoryCreatedEventStore do
  include EE::GeoHelpers

  set(:project) { create(:project) }
  set(:secondary_node) { create(:geo_node) }

  subject { described_class.new(project) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::RepositoryCreatedEvent

    context 'running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks information for the created project' do
        subject.create!

        expect(Geo::RepositoryCreatedEvent.last).to have_attributes(
          project_id: project.id,
          repo_path: project.disk_path,
          wiki_path: project.wiki.disk_path,
          project_name: project.name,
          repository_storage_name: project.repository_storage
        )
      end

      it 'does not set a wiki path if the wiki is disabled' do
        project.update!(wiki_enabled: false)

        subject.create!

        expect(Geo::RepositoryCreatedEvent.last.wiki_path).to be_nil
      end
    end
  end
end
