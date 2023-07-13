# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::Base, feature_category: :database do
  describe '#execute' do
    let(:structure_sql) { instance_double(Gitlab::Schema::Validation::Sources::StructureSql) }
    let(:database) { instance_double(Gitlab::Schema::Validation::Sources::Database) }

    subject(:inconsistencies) { described_class.new(structure_sql, database).execute }

    describe '.all_validators' do
      subject(:all_validators) { described_class.all_validators }

      it 'returns an array of all validators' do
        expect(all_validators).to eq([
          Gitlab::Schema::Validation::Validators::ExtraTables,
          Gitlab::Schema::Validation::Validators::ExtraTableColumns,
          Gitlab::Schema::Validation::Validators::ExtraIndexes,
          Gitlab::Schema::Validation::Validators::ExtraTriggers,
          Gitlab::Schema::Validation::Validators::ExtraForeignKeys,
          Gitlab::Schema::Validation::Validators::MissingTables,
          Gitlab::Schema::Validation::Validators::MissingTableColumns,
          Gitlab::Schema::Validation::Validators::MissingIndexes,
          Gitlab::Schema::Validation::Validators::MissingTriggers,
          Gitlab::Schema::Validation::Validators::MissingForeignKeys,
          Gitlab::Schema::Validation::Validators::DifferentDefinitionTables,
          Gitlab::Schema::Validation::Validators::DifferentDefinitionIndexes,
          Gitlab::Schema::Validation::Validators::DifferentDefinitionTriggers,
          Gitlab::Schema::Validation::Validators::DifferentDefinitionForeignKeys
        ])
      end
    end

    it 'raises an exception' do
      expect { inconsistencies }.to raise_error(NoMethodError)
    end
  end
end
