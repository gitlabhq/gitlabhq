# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::Preloads', :partitioning do
  let(:project) { Project.create! }

  let!(:pipeline) { Pipeline.create!(project: project, partition_id: 100) }
  let!(:other_pipeline) { Pipeline.create!(project: project, partition_id: 100) }

  let!(:job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }
  let!(:other_job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }

  describe 'preload queries with single partition' do
    it 'preloads metadata for jobs' do
      statement1 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\" WHERE \"jobs\".\"partition_id\" = 100
      SQL

      statement2 = <<~SQL.squish
        SELECT \"metadata\".* FROM \"metadata\"
        WHERE \"metadata\".\"partition_id\" = 100 AND \"metadata\".\"job_id\" IN (#{job.id}, #{other_job.id})
      SQL

      preload_statements = [statement1, statement2]

      result = QueryRecorder.log do
        Job.where(partition_id: 100).preload(:metadata).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end

    it 'preloads jobs for pipelines' do
      statement1 = <<~SQL.squish
        SELECT \"pipelines\".* FROM \"pipelines\" WHERE \"pipelines\".\"partition_id\" = 100
      SQL

      statement2 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 100 AND \"jobs\".\"pipeline_id\" IN (#{pipeline.id}, #{other_pipeline.id})
      SQL

      preload_statements = [statement1, statement2]

      result = QueryRecorder.log do
        Pipeline.where(partition_id: 100).preload(:jobs).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end

    it 'preloads jobs and metadata for pipelines' do
      statement1 = <<~SQL.squish
        SELECT \"pipelines\".* FROM \"pipelines\" WHERE \"pipelines\".\"partition_id\" = 100
      SQL

      statement2 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 100 AND \"jobs\".\"pipeline_id\" IN (#{pipeline.id}, #{other_pipeline.id})
      SQL

      statement3 = <<~SQL.squish
        SELECT \"metadata\".* FROM \"metadata\"
        WHERE \"metadata\".\"partition_id\" = 100 AND \"metadata\".\"job_id\" IN (#{job.id}, #{other_job.id})
      SQL

      preload_statements = [statement1, statement2, statement3]

      result = QueryRecorder.log do
        Pipeline.where(partition_id: 100).preload(jobs: :metadata).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end
  end

  describe 'preload queries with multiple partitions' do
    let!(:recent_pipeline) { Pipeline.create!(project: project, partition_id: 200) }
    let!(:test_job) { Job.create!(pipeline: recent_pipeline, partition_id: recent_pipeline.partition_id) }
    let!(:deploy_job) { Job.create!(pipeline: recent_pipeline, partition_id: recent_pipeline.partition_id) }

    it 'preloads metadata for jobs' do
      statement1 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\" WHERE \"jobs\".\"partition_id\" IN (100, 200)
      SQL

      statement2 = <<~SQL.squish
        SELECT \"metadata\".* FROM \"metadata\"
        WHERE \"metadata\".\"partition_id\" = 100 AND \"metadata\".\"job_id\" IN (#{job.id}, #{other_job.id})
      SQL

      statement3 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\" WHERE \"jobs\".\"partition_id\" IN (100, 200)
      SQL

      preload_statements = [statement1, statement2, statement3]

      result = QueryRecorder.log do
        Job.where(partition_id: [100, 200]).preload(:metadata).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end

    it 'preloads jobs for pipelines' do
      statement1 = <<~SQL.squish
        SELECT \"pipelines\".* FROM \"pipelines\" WHERE \"pipelines\".\"partition_id\" IN (100, 200)
      SQL

      statement2 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 100 AND \"jobs\".\"pipeline_id\" IN (#{pipeline.id}, #{other_pipeline.id})
      SQL

      statement3 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 200 AND \"jobs\".\"pipeline_id\" = #{recent_pipeline.id}
      SQL

      preload_statements = [statement1, statement2, statement3]

      result = QueryRecorder.log do
        Pipeline.where(partition_id: [100, 200]).preload(:jobs).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end

    it 'preloads jobs and metadata for pipelines' do
      statement1 = <<~SQL.squish
        SELECT \"pipelines\".* FROM \"pipelines\" WHERE \"pipelines\".\"partition_id\" IN (100, 200)
      SQL

      statement2 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 100 AND \"jobs\".\"pipeline_id\" IN (#{pipeline.id}, #{other_pipeline.id})
      SQL

      statement3 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 200 AND \"jobs\".\"pipeline_id\" = #{recent_pipeline.id}
      SQL

      statement4 = <<~SQL.squish
        SELECT \"metadata\".* FROM \"metadata\"
        WHERE \"metadata\".\"partition_id\" = 100 AND \"metadata\".\"job_id\" IN (#{job.id}, #{other_job.id})
      SQL

      statement5 = <<~SQL.squish
        SELECT \"metadata\".* FROM \"metadata\"
        WHERE \"metadata\".\"partition_id\" = 200 AND \"metadata\".\"job_id\" IN (#{test_job.id}, #{deploy_job.id})
      SQL

      preload_statements = [statement1, statement2, statement3, statement4, statement5]

      result = QueryRecorder.log do
        Pipeline.where(partition_id: [100, 200]).preload(jobs: :metadata).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end
  end

  describe 'includes queries' do
    it 'preloads data for pipeline with multiple queries' do
      statement1 = <<~SQL.squish
        SELECT \"pipelines\".* FROM \"pipelines\"
        WHERE \"pipelines\".\"project_id\" = 1 AND \"pipelines\".\"id\"
        IN (#{pipeline.id}, #{other_pipeline.id}) AND \"pipelines\".\"partition_id\" = 100
      SQL

      statement2 = <<~SQL.squish
        SELECT \"jobs\".* FROM \"jobs\"
        WHERE \"jobs\".\"partition_id\" = 100 AND \"jobs\".\"pipeline_id\" IN (#{pipeline.id}, #{other_pipeline.id})
      SQL

      statement3 = <<~SQL.squish
        SELECT \"metadata\".* FROM \"metadata\"
        WHERE \"metadata\".\"partition_id\" = 100 AND \"metadata\".\"job_id\" IN (#{job.id}, #{other_job.id})
      SQL

      preload_statements = [statement1, statement2, statement3]

      result = QueryRecorder.log do
        project.pipelines.includes(jobs: :metadata).where(id: [pipeline.id, other_pipeline.id], partition_id: 100).to_a
      end

      preload_statements.each do |statement|
        expect(result).to include(statement)
      end
    end

    it 'preloads data for pipeline with join query' do
      preload_statement = <<~SQL.squish
        SELECT \"pipelines\".\"id\"
        AS t0_r0, \"pipelines\".\"project_id\"
        AS t0_r1, \"pipelines\".\"partition_id\"
        AS t0_r2, \"jobs\".\"id\"
        AS t1_r0, \"jobs\".\"pipeline_id\"
        AS t1_r1, \"jobs\".\"partition_id\"
        AS t1_r2, \"jobs\".\"name\"
        AS t1_r3, \"metadata\".\"id\"
        AS t2_r0, \"metadata\".\"job_id\"
        AS t2_r1, \"metadata\".\"partition_id\"
        AS t2_r2, \"metadata\".\"test_flag\"
        AS t2_r3
        FROM \"pipelines\"
        LEFT OUTER JOIN \"jobs\" ON \"jobs\".\"partition_id\" IS NOT NULL
        AND \"jobs\".\"pipeline_id\" = \"pipelines\".\"id\"
        AND \"jobs\".\"partition_id\" = \"pipelines\".\"partition_id\"
        LEFT OUTER JOIN \"metadata\" ON \"metadata\".\"partition_id\" IS NOT NULL
        AND \"metadata\".\"job_id\" = \"jobs\".\"id\"
        AND \"metadata\".\"partition_id\" = \"jobs\".\"partition_id\"
        WHERE \"pipelines\".\"project_id\" = 1
        AND \"pipelines\".\"id\"
        IN (#{pipeline.id}, #{other_pipeline.id})
        AND \"pipelines\".\"partition_id\" = 100
      SQL

      result = QueryRecorder.log do
        project
          .pipelines
          .includes(jobs: :metadata)
          .references(:jobs, :metadata)
          .where(id: [1, 2], partition_id: 100)
          .to_a
      end

      expect(result).to include(preload_statement)
    end

    it 'keeps join conditions from scope' do
      preload_statement = <<~SQL.squish
        SELECT \"pipelines\".\"id\"
        AS t0_r0, \"pipelines\".\"project_id\"
        AS t0_r1, \"pipelines\".\"partition_id\"
        AS t0_r2, \"jobs\".\"id\"
        AS t1_r0, \"jobs\".\"pipeline_id\"
        AS t1_r1, \"jobs\".\"partition_id\"
        AS t1_r2, \"jobs\".\"name\"
        AS t1_r3, \"metadata\".\"id\"
        AS t2_r0, \"metadata\".\"job_id\"
        AS t2_r1, \"metadata\".\"partition_id\"
        AS t2_r2, \"metadata\".\"test_flag\"
        AS t2_r3
        FROM \"pipelines\"
        LEFT OUTER JOIN \"jobs\" ON \"jobs\".\"partition_id\" IS NOT NULL
        AND \"jobs\".\"pipeline_id\" = \"pipelines\".\"id\"
        AND \"jobs\".\"partition_id\" = \"pipelines\".\"partition_id\"
        LEFT OUTER JOIN \"metadata\" ON \"metadata\".\"test_flag\" = 1
        AND \"metadata\".\"partition_id\" IS NOT NULL
        AND \"metadata\".\"job_id\" = \"jobs\".\"id\"
        AND \"metadata\".\"partition_id\" = \"jobs\".\"partition_id\"
        WHERE \"pipelines\".\"project_id\" = 1
        AND \"pipelines\".\"id\"
        IN (#{pipeline.id}, #{other_pipeline.id})
        AND \"pipelines\".\"partition_id\" = 100
      SQL

      result = QueryRecorder.log do
        project
          .pipelines
          .includes(jobs: :test_metadata)
          .references(:jobs, :test_metadata)
          .where(id: [1, 2], partition_id: 100)
          .to_a
      end

      expect(result).to include(preload_statement)
    end

    it 'does rewhere the partition_id condition when missing' do
      preload_statement = <<~SQL.squish
        SELECT \"pipelines\".\"id\"
        AS t0_r0, \"pipelines\".\"project_id\"
        AS t0_r1, \"pipelines\".\"partition_id\"
        AS t0_r2, \"jobs\".\"id\"
        AS t1_r0, \"jobs\".\"pipeline_id\"
        AS t1_r1, \"jobs\".\"partition_id\"
        AS t1_r2, \"jobs\".\"name\"
        AS t1_r3 FROM \"pipelines\"
        LEFT OUTER JOIN \"jobs\" ON \"jobs\".\"pipeline_id\" = NULL
        AND \"jobs\".\"pipeline_id\" = \"pipelines\".\"id\"
        AND \"jobs\".\"partition_id\" = \"pipelines\".\"partition_id\"
        WHERE \"pipelines\".\"project_id\" = 1
        AND \"pipelines\".\"id\" IN (1, 2)
        AND \"pipelines\".\"partition_id\" = 100
      SQL

      result = QueryRecorder.log do
        project
          .pipelines
          .includes(:unpartitioned_jobs)
          .references(:unpartitioned_jobs)
          .where(id: [1, 2], partition_id: 100)
          .to_a
      end

      expect(result).to include(preload_statement)
    end
  end
end
