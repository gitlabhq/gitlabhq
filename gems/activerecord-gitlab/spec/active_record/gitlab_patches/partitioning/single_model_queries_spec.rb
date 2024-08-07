# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::SingleModelQueries', :partitioning do
  let(:project) { Project.create! }
  let(:pipeline) { Pipeline.create!(project: project, partition_id: 100) }
  let(:job) { Job.create!(pipeline: pipeline, partition_id: pipeline.partition_id) }

  it 'creates using id and partition_id' do
    create_statement = <<~SQL.squish
      INSERT INTO \"jobs\" (\"pipeline_id\", \"partition_id\")
      VALUES (#{pipeline.id}, #{pipeline.partition_id})
    SQL

    result = QueryRecorder.log do
      Job.create!(pipeline_id: pipeline.id, partition_id: pipeline.partition_id)
    end.join

    expect(result).to include(create_statement)
  end

  it 'finds with id and partition_id' do
    find_statement = <<~SQL.squish
      SELECT \"jobs\".*
      FROM \"jobs\"
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{job.partition_id}
      LIMIT 1
    SQL

    result = QueryRecorder.log do
      Job.find_by!(id: job.id, partition_id: job.partition_id)
    end

    expect(result).to include(find_statement)
  end

  it 'saves using id and partition_id' do
    update_statement = <<~SQL.squish
      UPDATE \"jobs\"
      SET \"name\" = 'test'
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{job.partition_id}
    SQL

    result = QueryRecorder.log do
      job.name = 'test'

      job.save!
    end

    expect(result).to include(update_statement)
  end

  it 'updates using id and partition_id' do
    update_statement = <<~SQL.squish
      UPDATE \"jobs\"
      SET \"name\" = 'test2'
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{job.partition_id}
    SQL

    result = QueryRecorder.log do
      job.update!(name: 'test2')
    end

    expect(result).to include(update_statement)
  end

  it 'deletes using id and partition_id' do
    delete_statement = <<~SQL.squish
      DELETE FROM \"jobs\"
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{job.partition_id}
    SQL

    result = QueryRecorder.log do
      job.delete
    end

    expect(result).to include(delete_statement)
  end

  it 'destroys using id and partition_id' do
    destroy_statement = <<~SQL.squish
      DELETE FROM \"jobs\"
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{job.partition_id}
    SQL

    result = QueryRecorder.log do
      job.destroy
    end

    expect(result).to include(destroy_statement)
  end

  it 'destroy_all using partition_id' do
    destroy_statement = <<~SQL.squish
      DELETE FROM \"jobs\"
      WHERE \"jobs\".\"id\" = #{job.id}
      AND \"jobs\".\"partition_id\" = #{job.partition_id}
    SQL

    result = QueryRecorder.log do
      Job.where(id: job.id).destroy_all # rubocop: disable Cop/DestroyAll
    end

    expect(result).to include(destroy_statement)
  end
end
