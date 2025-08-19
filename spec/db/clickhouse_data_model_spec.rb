# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse Group hierarchy data model', :click_house, feature_category: :database do
  let(:connection) { ClickHouse::Connection.new(:main) }

  before do
    # namespaces
    namespaces_query = <<~SQL
    INSERT INTO siphon_namespaces (id, traversal_ids, organization_id)
    VALUES ({id:UInt64}, {traversal_ids:Array(UInt64)}, {organization_id:UInt64})
    SQL

    placeholders = { id: 1, traversal_ids: [1], organization_id: 10 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: namespaces_query, placeholders: placeholders))

    placeholders = { id: 2, traversal_ids: [1, 2], organization_id: 10 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: namespaces_query, placeholders: placeholders))

    # labels
    labels_query = <<~SQL
    INSERT INTO siphon_label_links (id, label_id, target_id, target_type)
    VALUES ({id:UInt64}, {label_id:UInt64}, {target_id:UInt64}, {target_type:String})
    SQL

    placeholders = { id: 2, label_id: 100, target_id: 1000, target_type: 'Issue' }
    connection.execute(ClickHouse::Client::Query.new(raw_query: labels_query, placeholders: placeholders))

    placeholders = { id: 3, label_id: 101, target_id: 1000, target_type: 'Issue' }
    connection.execute(ClickHouse::Client::Query.new(raw_query: labels_query, placeholders: placeholders))

    placeholders = { id: 4, label_id: 101, target_id: 1001, target_type: 'Issue' }
    connection.execute(ClickHouse::Client::Query.new(raw_query: labels_query, placeholders: placeholders))

    placeholders = { id: 5, label_id: 101, target_id: 1001, target_type: 'MergeRequest' } # record should be ignored
    connection.execute(ClickHouse::Client::Query.new(raw_query: labels_query, placeholders: placeholders))

    # assignees
    assignees_query = <<~SQL
    INSERT INTO siphon_issue_assignees (user_id, issue_id)
    VALUES ({user_id:UInt64}, {issue_id:UInt64})
    SQL

    placeholders = { user_id: 10_000, issue_id: 1000 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: assignees_query, placeholders: placeholders))

    placeholders = { user_id: 10_001, issue_id: 1001 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: assignees_query, placeholders: placeholders))

    placeholders = { user_id: 10_002, issue_id: 1001 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: assignees_query, placeholders: placeholders))

    # issues
    issues_query = <<~SQL
    INSERT INTO siphon_issues (id, namespace_id, work_item_type_id, title, author_id)
    VALUES ({id:UInt64}, {namespace_id:UInt64}, {work_item_type_id:UInt64}, {title:String}, {author_id:UInt64})
    SQL

    placeholders = { id: 1000, namespace_id: 1, work_item_type_id: 2, title: 'Issue 1', author_id: 5 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: issues_query, placeholders: placeholders))

    placeholders = { id: 1001, namespace_id: 2, work_item_type_id: 2, title: 'Issue 2', author_id: 10 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: issues_query, placeholders: placeholders))

    # simulating missing namespace
    placeholders = { id: 1002, namespace_id: 3, work_item_type_id: 2, title: 'Issue 3', author_id: 10 }
    connection.execute(ClickHouse::Client::Query.new(raw_query: issues_query, placeholders: placeholders))
  end

  it 'populates the materialized views correctly' do
    rows = connection.select("SELECT id, traversal_path FROM namespace_traversal_paths FINAL ORDER BY id")

    expect(rows).to eq([
      { 'id' => '1', 'traversal_path' => '10/1/' },
      { 'id' => '2', 'traversal_path' => '10/1/2/' }
    ])

    rows = connection.select("SELECT work_item_id, label_id FROM work_item_label_links FINAL ORDER BY id")

    expect(rows).to eq([
      { 'work_item_id' => '1000', 'label_id' => '100' },
      { 'work_item_id' => '1000', 'label_id' => '101' },
      { 'work_item_id' => '1001', 'label_id' => '101' }
    ])

    query = <<~SQL
    SELECT id, traversal_path, namespace_id, work_item_type_id, title, author_id, label_ids, assignee_ids
    FROM hierarchy_work_items FINAL ORDER BY id
    SQL

    rows = connection.select(query)

    expect(rows).to eq([
      { 'id' => '1000', 'traversal_path' => '10/1/', 'namespace_id' => '1', 'work_item_type_id' => '2',
        'title' => 'Issue 1', 'author_id' => '5', 'label_ids' => '/100/101/', 'assignee_ids' => '/10000/' },
      { 'id' => '1001', 'traversal_path' => '10/1/2/', 'namespace_id' => '2', 'work_item_type_id' => '2',
        'title' => 'Issue 2', 'author_id' => '10', 'label_ids' => '/101/', 'assignee_ids' => '/10001/10002/' },
      { 'id' => '1002', 'traversal_path' => '', 'namespace_id' => '3', 'work_item_type_id' => '2',
        'title' => 'Issue 3', 'author_id' => '10', 'label_ids' => '', 'assignee_ids' => '' }
    ])
  end
end
