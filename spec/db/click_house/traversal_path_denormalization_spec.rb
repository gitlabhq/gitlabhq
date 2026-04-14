# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'traversal_path de-normalization', :click_house, feature_category: :database do
  let(:conn) { ClickHouse::Connection.new(:main) }

  let(:namespace_traversal_paths) do
    conn
      .select('SELECT id, traversal_path FROM namespace_traversal_paths FINAL ORDER BY id')
      .pluck('id', 'traversal_path')
  end

  let(:project_namespace_traversal_paths) do
    conn
      .select('SELECT id, traversal_path FROM project_namespace_traversal_paths FINAL ORDER BY id')
      .pluck('id', 'traversal_path')
  end

  before do
    conn.execute <<~SQL
    INSERT INTO siphon_namespaces (id, organization_id, traversal_ids, type) VALUES
    (1, 1, '[1]', 'Group'),
    (2, 1, '[1, 2]', 'Project'),
    (3, 1, '[1, 3]', 'Project'),
    (4, 1, '[1, 4]', 'Group'),
    (100, 2, '[100]', 'Group'),
    (1000, 2, '[100, 1000]', 'Group')
    SQL

    conn.execute <<~SQL
    INSERT INTO siphon_projects (id, organization_id, namespace_id, project_namespace_id) VALUES
    (1, 1, 1, 2),
    (5, 1, 1, 3),
    (10, 2, 100, 1000)
    SQL
  end

  it 'correctly stores the traversal_paths' do
    expect(namespace_traversal_paths).to eq([
      [1, '1/1/'],
      [2, '1/1/2/'],
      [3, '1/1/3/'],
      [4, '1/1/4/'],
      [100, '2/100/'],
      [1000, '2/100/1000/']
    ])

    expect(project_namespace_traversal_paths).to eq([
      [1, '1/1/2/'],
      [5, '1/1/3/'],
      [10, '2/100/1000/']
    ])
  end

  context 'when project namespace is moved' do
    it 'updates both traversal_paths tables' do
      # namespace id=3 is moved under a subgroup id=4
      conn.execute <<~SQL
      INSERT INTO siphon_namespaces (id, organization_id, traversal_ids, type)
      VALUES (3, 1, '[1, 4, 3]', 'Project')
      SQL

      expect(namespace_traversal_paths).to eq([
        [1, '1/1/'],
        [2, '1/1/2/'],
        [3, '1/1/4/3/'],
        [4, '1/1/4/'],
        [100, '2/100/'],
        [1000, '2/100/1000/']
      ])

      expect(project_namespace_traversal_paths).to eq([
        [1, '1/1/2/'],
        [5, '1/1/4/3/'],
        [10, '2/100/1000/']
      ])
    end
  end
end
