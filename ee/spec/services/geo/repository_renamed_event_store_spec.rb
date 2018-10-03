# frozen_string_literal: true

require 'spec_helper'

describe Geo::RepositoryRenamedEventStore do
  include EE::GeoHelpers

  set(:project) { create(:project, path: 'bar') }
  set(:secondary_node) { create(:geo_node) }

  let(:old_path) { 'foo' }
  let(:old_path_with_namespace) { "#{project.namespace.full_path}/foo" }

  subject { described_class.new(project, old_path: old_path, old_path_with_namespace: old_path_with_namespace) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::RepositoryRenamedEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks old and new paths for project repositories' do
        subject.create!

        expect(Geo::RepositoryRenamedEvent.last).to have_attributes(
          repository_storage_name: project.repository_storage,
          old_path_with_namespace: old_path_with_namespace,
          new_path_with_namespace: project.disk_path,
          old_wiki_path_with_namespace: "#{old_path_with_namespace}.wiki",
          new_wiki_path_with_namespace: project.wiki.disk_path,
          old_path: old_path,
          new_path: project.path
        )
      end
    end
  end
end
