# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::HasOne', :partitioning do
  let(:pipeline) { Pipeline.create!(partition_id: 100) }
  let(:job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }

  it 'finds associated record using partition_id' do
    find_statement = <<~SQL.squish
      SELECT \"metadata\".*
      FROM \"metadata\"
      WHERE \"metadata\".\"job_id\" = #{job.id}
      AND \"metadata\".\"partition_id\" = #{job.partition_id}
      LIMIT 1
    SQL

    result = QueryRecorder.log do
      job.reset.metadata
    end

    expect(result).to include(find_statement)
  end

  it 'builds records using partition_id' do
    metadata = job.build_metadata

    expect(metadata.job_id).to eq(job.id)
    expect(metadata.partition_id).to eq(job.partition_id)
  end

  it 'saves records using partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"metadata\" (\"job_id\", \"partition_id\") VALUES (#{job.id}, #{job.partition_id})
    SQL

    result = QueryRecorder.log do
      job.build_metadata.save!
    end.join

    expect(result).to include(create_statement)
  end

  it 'creates records using partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"metadata\" (\"job_id\", \"partition_id\") VALUES (#{job.id}, #{job.partition_id})
    SQL

    result = QueryRecorder.log do
      job.create_metadata
    end.join

    expect(result).to include(create_statement)
  end

  it 'uses nested attributes on create' do
    skip '`partitionable` will assign the `partition_id` value in this case.'

    statement1 = <<~SQL.squish
      INSERT INTO \"jobs\" (\"pipeline_id\", \"partition_id\", \"name\")
      VALUES (#{pipeline.id}, #{pipeline.partition_id}, 'test')
    SQL

    statement2 = <<~SQL.squish
      INSERT INTO \"metadata\" (\"job_id\", \"partition_id\", \"test_flag\")
      VALUES (#{job.id}, #{job.partition_id}, 1)
    SQL

    insert_statements = [statement1, statement2]

    result = QueryRecorder.log do
      pipeline.jobs.create!(name: 'test', metadata_attributes: { test_flag: true })
    end

    insert_statements.each do |statement|
      expect(result).to include(statement)
    end
  end

  it 'uses nested attributes on update' do
    statement1 = <<~SQL.squish
      UPDATE \"jobs\" SET \"name\" = 'other test'
      WHERE \"jobs\".\"id\" = #{job.id} AND \"jobs\".\"partition_id\" = #{job.partition_id}
    SQL

    statement2 = <<~SQL.squish
      INSERT INTO \"metadata\" (\"job_id\", \"partition_id\", \"test_flag\") VALUES (#{job.id}, #{job.partition_id}, 1)
    SQL

    update_statements = [statement1, statement2]

    job.name = 'other test'
    job.metadata_attributes = { test_flag: true }

    result = QueryRecorder.log do
      job.save!
    end.join

    update_statements.each do |statement|
      expect(result).to include(statement)
    end
  end
end
