# frozen_string_literal: true

require 'spec_helper'

describe Geo::RepositoryDeletedEventStore do
  include EE::GeoHelpers

  set(:project) { create(:project, path: 'bar') }
  set(:secondary_node) { create(:geo_node) }

  let(:project_id) { project.id }
  let(:project_name) { project.name }
  let(:repo_path) { project.full_path }
  let(:wiki_path) { "#{project.full_path}.wiki" }
  let(:storage_name) { project.repository_storage }

  subject { described_class.new(project, repo_path: repo_path, wiki_path: wiki_path) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::RepositoryDeletedEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks information for the deleted project' do
        subject.create!

        expect(Geo::RepositoryDeletedEvent.last).to have_attributes(
          project_id: project_id,
          deleted_path: repo_path,
          deleted_wiki_path: wiki_path,
          deleted_project_name: project_name,
          repository_storage_name: storage_name
        )
      end
    end
  end
end
