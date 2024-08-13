# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::HasMany', :partitioning do
  let(:pipeline) { Pipeline.create!(partition_id: 100) }
  let(:job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }

  it 'finds individual records using partition_id' do
    find_statement = <<~SQL.squish
      SELECT \"jobs\".*
      FROM \"jobs\"
      WHERE \"jobs\".\"pipeline_id\" = #{pipeline.id}
      AND \"jobs\".\"partition_id\" = #{pipeline.partition_id}
      AND \"jobs\".\"id\" = #{job.id}
      LIMIT 1
    SQL

    result = QueryRecorder.log do
      pipeline.jobs.find(job.id)
    end

    expect(result).to include(find_statement)
  end

  it 'finds all records using partition_id' do
    find_statement = <<~SQL.squish
      SELECT \"jobs\".*
      FROM \"jobs\"
      WHERE \"jobs\".\"pipeline_id\" = #{pipeline.id}
      AND \"jobs\".\"partition_id\" = #{pipeline.partition_id}
    SQL

    result = QueryRecorder.log do
      pipeline.jobs.all.to_a
    end

    expect(result).to include(find_statement)
  end

  it 'jobs records using partition_id' do
    build = pipeline.jobs.new(name: 'test job')

    expect(build.pipeline_id).to eq(pipeline.id)
    expect(build.partition_id).to eq(pipeline.partition_id)
  end

  it 'saves records using partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"jobs\" (\"pipeline_id\", \"partition_id\", \"name\")
      VALUES (#{pipeline.id}, #{pipeline.partition_id}, 'test job')
    SQL

    result = QueryRecorder.log do
      build = pipeline.jobs.new(name: 'test job')
      build.save!
    end.join

    expect(result).to include(create_statement)
  end

  it 'creates records using partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"jobs\" (\"pipeline_id\", \"partition_id\", \"name\")
      VALUES (#{pipeline.id}, #{pipeline.partition_id}, 'test job')
    SQL

    result = QueryRecorder.log do
      pipeline.jobs.create!(name: 'test job')
    end.join

    expect(result).to include(create_statement)
  end

  it 'deletes_all records using partition_id' do
    delete_statement = <<~SQL.squish
      DELETE FROM \"jobs\"
      WHERE \"jobs\".\"pipeline_id\" = #{pipeline.id}
      AND \"jobs\".\"partition_id\" = #{pipeline.partition_id}
    SQL

    result = QueryRecorder.log do
      pipeline.jobs.delete_all
    end

    expect(result).to include(delete_statement)
  end

  it 'destroy_all records using partition_id' do
    destroy_statement = <<~SQL.squish
      DELETE FROM \"jobs\"
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{pipeline.partition_id}
    SQL

    result = QueryRecorder.log do
      pipeline.jobs.destroy_all # rubocop: disable Cop/DestroyAll
    end

    expect(result).to include(destroy_statement)
  end

  it 'counts records using partition_id' do
    destroy_statement = <<~SQL.squish
      SELECT COUNT(*)
      FROM \"jobs\"
      WHERE \"jobs\".\"pipeline_id\" = #{pipeline.id}
      AND \"jobs\".\"partition_id\" = #{pipeline.partition_id}
    SQL

    result = QueryRecorder.log do
      pipeline.jobs.count
    end

    expect(result).to include(destroy_statement)
  end
end
