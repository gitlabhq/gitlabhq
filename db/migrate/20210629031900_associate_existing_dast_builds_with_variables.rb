# frozen_string_literal: true

class AssociateExistingDastBuildsWithVariables < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  class Profile < ApplicationRecord
    self.table_name = 'dast_profiles'
    self.inheritance_column = :_type_disabled
  end

  class ProfilesPipeline < ApplicationRecord
    include EachBatch

    self.table_name = 'dast_profiles_pipelines'
    self.inheritance_column = :_type_disabled

    belongs_to :profile, foreign_key: :dast_profile_id
  end

  class Build < ApplicationRecord
    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled

    default_scope { where(name: :dast, stage: :dast) } # rubocop:disable Cop/DefaultScope
  end

  class SiteProfilesBuild < ApplicationRecord
    self.table_name = 'dast_site_profiles_builds'
    self.inheritance_column = :_type_disabled
  end

  BATCH_SIZE = 300

  def up
    process_batch do |batch|
      bulk_inserts = []

      grouped_builds = fetch_builds(batch).group_by(&:commit_id)

      batch.includes(:profile).each do |profile_pipeline|
        builds = grouped_builds[profile_pipeline.ci_pipeline_id]

        next if builds.blank?

        builds.each do |build|
          bulk_inserts.push(dast_site_profile_id: profile_pipeline.profile.dast_site_profile_id, ci_build_id: build.id)
        end
      end

      SiteProfilesBuild.insert_all(bulk_inserts, unique_by: :ci_build_id)
    end
  end

  def down
    process_batch do |batch|
      builds = fetch_builds(batch)

      SiteProfilesBuild
        .where(ci_build_id: builds)
        .delete_all
    end
  end

  private

  def fetch_builds(batch)
    # pluck necessary to support ci table decomposition
    # https://gitlab.com/groups/gitlab-org/-/epics/6289
    Build.where(commit_id: batch.pluck(:ci_pipeline_id))
  end

  def process_batch
    ProfilesPipeline.each_batch(of: BATCH_SIZE, column: :ci_pipeline_id) do |batch|
      yield(batch)
    end
  end
end
