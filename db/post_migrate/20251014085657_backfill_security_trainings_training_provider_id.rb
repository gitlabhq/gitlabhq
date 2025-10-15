# frozen_string_literal: true

class BackfillSecurityTrainingsTrainingProviderId < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.6'

  def up
    define_batchable_model(:security_trainings).each_batch(of: 500) do |batch|
      attributes = batch.map do |row|
        dynamic_provider_id = row.provider_id
        static_provider_id = mappings[dynamic_provider_id]
        { id: row.id, project_id: row.project_id, training_provider_id: static_provider_id }
      end

      define_batchable_model(:security_trainings).upsert_all(
        attributes,
        update_only: %i[training_provider_id]
      )
    end
  end

  def down
    # no-op
  end

  private

  def mappings
    @mappings ||= ::Security::TrainingProvider.all.map do |tp|
      static_provider = ::Security::StaticTrainingProvider.find_by(name: tp.name)
      # This can happen only if someone manually added a training provider to their table
      next unless static_provider

      { tp.id => static_provider.id }
    end.reduce(&:merge)
  end
end
