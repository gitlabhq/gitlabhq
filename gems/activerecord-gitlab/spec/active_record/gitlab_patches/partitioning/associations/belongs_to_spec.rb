# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::BelongsTo', :partitioning do
  let(:pipeline) { Pipeline.create!(partition_id: 100) }
  let(:job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }

  it 'finds associated record using partition_id' do
    find_statement = <<~SQL.squish
      SELECT \"pipelines\".*
      FROM \"pipelines\"
      WHERE \"pipelines\".\"id\" = #{pipeline.id}
      AND \"pipelines\".\"partition_id\" = #{job.partition_id}
      LIMIT 1
    SQL

    result = QueryRecorder.log do
      job.reset.pipeline
    end

    expect(result).to include(find_statement)
  end

  it 'builds records using partition_id' do
    pipeline = job.build_pipeline

    expect(pipeline.partition_id).to eq(job.partition_id)
  end

  it 'saves records using partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"pipelines\" (\"partition_id\") VALUES (#{job.partition_id})
    SQL

    result = QueryRecorder.log do
      job.build_pipeline.save!
    end.join

    expect(result).to include(create_statement)
  end

  it 'creates records using partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"pipelines\" (\"partition_id\") VALUES (#{job.partition_id})
    SQL

    result = QueryRecorder.log do
      job.create_pipeline!
    end.join

    expect(result).to include(create_statement)
  end
end
