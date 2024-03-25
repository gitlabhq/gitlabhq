# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::Joins', :partitioning do
  let!(:pipeline) { Pipeline.create!(partition_id: 100) }
  let!(:job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }
  let!(:metadata) { Metadata.create!(job: job, partition_id: job.partition_id) }

  it 'joins using partition_id' do
    join_statement = <<~SQL.squish
      SELECT \"pipelines\".*
      FROM \"pipelines\"
      INNER JOIN \"jobs\" ON \"jobs\".\"partition_id\" IS NOT NULL
      AND \"jobs\".\"pipeline_id\" = \"pipelines\".\"id\"
      AND \"jobs\".\"partition_id\" = \"pipelines\".\"partition_id\"
      WHERE \"pipelines\".\"partition_id\" = #{pipeline.partition_id}
    SQL

    result = QueryRecorder.log do
      Pipeline.where(partition_id: pipeline.partition_id).joins(:jobs).to_a
    end

    expect(result).to include(join_statement)
  end

  it 'joins other models using partition_id' do
    join_statement = <<~SQL.squish
      SELECT \"pipelines\".*
      FROM \"pipelines\"
      INNER JOIN \"jobs\" ON \"jobs\".\"partition_id\" IS NOT NULL
      AND \"jobs\".\"pipeline_id\" = \"pipelines\".\"id\"
      AND \"jobs\".\"partition_id\" = \"pipelines\".\"partition_id\"
      INNER JOIN \"metadata\" ON \"metadata\".\"partition_id\" IS NOT NULL
      AND \"metadata\".\"job_id\" = \"jobs\".\"id\"
      AND \"metadata\".\"partition_id\" = \"jobs\".\"partition_id\"
      WHERE \"pipelines\".\"partition_id\" = #{pipeline.partition_id}
    SQL

    result = QueryRecorder.log do
      Pipeline.where(partition_id: pipeline.partition_id).joins(jobs: :metadata).to_a
    end

    expect(result).to include(join_statement)
  end
end
