# encoding: utf-8

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20180417102933_drop_repository_storage_events_for_geo_events.rb')

describe DropRepositoryStorageEventsForGeoEvents, :migration do
  describe '#up' do
    before do
      schema_migrate_up!
    end

    where(table_name: described_class::TABLES)
    with_them do
      it 'dropped the repository_storage_path column' do
        columns = table(table_name).columns.map(&:name)

        expect(columns).not_to include("repository_storage_path")
      end
    end
  end

  describe '#down' do
    let(:namespace) { table(:namespaces).create!(name: 'foo', path: 'foo_namespace') }
    let(:project) { table(:projects).create!(name: 'bar', path: 'path/to/bar', namespace_id: namespace.id) }

    shared_examples 'recreates the repository_storage_path column' do
      before do
        schema_migrate_up!

        Gitlab.config.repositories.storages.each do |name, _|
          table(table_name).create!({ project_id: project.id, repository_storage_name: name }.merge(extra_cols))
        end

        schema_migrate_down!
      end

      it 'creates repository_storage_path column' do
        columns = table(table_name).columns.map(&:name)

        expect(columns).to include("repository_storage_path")
      end

      it 'fills in all repository_storage_path cells' do
        null_columns = described_class
          .exec_query("SELECT COUNT(*) as count FROM #{table_name} WHERE repository_storage_path IS NULL;")
          .first['count']

        expect(null_columns.to_i).to eq(0)
      end

      it 'fills in repository_storage_path with the legacy_disk_path' do
        described_class.exec_query("SELECT repository_storage_name, repository_storage_path FROM #{table_name};").each do |row|
          expect(row['repository_storage_path']).to eq(legacy_disk_path(row['repository_storage_name']))
        end
      end
    end

    context 'geo_hashed_storage_migrated_events' do
      let(:table_name) { :geo_hashed_storage_migrated_events }
      let(:extra_cols) do
        {
          old_disk_path: '/ye/olde/path', new_disk_path: 'da39a3ee5e6b4b0d3255bfef95601890afd80709',
          old_wiki_disk_path: '/ye/olde/path.wiki', new_wiki_disk_path: 'da39a3ee5e6b4b0d3255bfef95601890afd80709.wiki',
          new_storage_version: 2
        }
      end

      it_behaves_like 'recreates the repository_storage_path column'
    end

    context 'geo_repository_created_events' do
      let(:table_name) { :geo_repository_created_events }
      let(:extra_cols) { { project_name: project.name, repo_path: project.path } }

      it_behaves_like 'recreates the repository_storage_path column'
    end

    context 'geo_repository_deleted_events' do
      let(:table_name) { :geo_repository_deleted_events }
      let(:extra_cols) { { deleted_path: '/null/path', deleted_project_name: 'im_gone' } }

      it_behaves_like 'recreates the repository_storage_path column'
    end

    context 'geo_repository_renamed_events' do
      let(:table_name) { :geo_repository_renamed_events }
      let(:extra_cols) do
        {
          old_path: '/ye/olde/path', new_path: '/ze/n3w/p4th',
          old_path_with_namespace: '/ye/olde/namespace/path', new_path_with_namespace: '/ze/n3w/n4mesp4ce/p4th',
          old_wiki_path_with_namespace: '/ye/olde/namespace/path.wiki', new_wiki_path_with_namespace: '/ze/n3w/n4mesp4ce/p4th.wiki'
        }
      end

      it_behaves_like 'recreates the repository_storage_path column'
    end
  end

  def legacy_disk_path(name)
    Gitlab.config.repositories.storages[name].legacy_disk_path
  end
end
