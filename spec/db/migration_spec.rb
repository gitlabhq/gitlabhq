# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migrations Validation', feature_category: :database do
  using RSpec::Parameterized::TableSyntax

  # The range describes the timestamps that given migration helper can be used
  let(:all_migration_classes) do
    {
      2023_10_10_02_15_00.. => Gitlab::Database::Migration[2.2],
      2022_12_01_02_15_00..2023_11_01_02_15_00 => Gitlab::Database::Migration[2.1],
      2022_01_26_21_06_58..2023_01_11_12_45_12 => Gitlab::Database::Migration[2.0],
      2021_09_01_15_33_24..2022_04_25_12_06_03 => Gitlab::Database::Migration[1.0],
      2021_05_31_05_39_16..2021_09_01_15_33_24 => ActiveRecord::Migration[6.1],
      ..2021_05_31_05_39_16 => ActiveRecord::Migration[6.0]
    }
  end

  where(:migration) do
    Gitlab::Database.database_base_models.flat_map do |_, model|
      model.connection.migration_context.migrations
    end.uniq
  end

  with_them do
    let(:migration_instance) { migration.send(:migration) }
    let(:allowed_migration_classes) { all_migration_classes.select { |r, _| r.include?(migration.version) }.values }

    it 'uses one of the allowed migration classes' do
      expect(allowed_migration_classes).to include(be > migration_instance.class)
    end
  end
end
