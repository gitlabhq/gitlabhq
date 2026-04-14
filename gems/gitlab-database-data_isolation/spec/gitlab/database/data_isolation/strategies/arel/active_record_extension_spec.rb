# frozen_string_literal: true

RSpec.describe Gitlab::Database::DataIsolation::Strategies::Arel::ActiveRecordExtension do
  let(:organization_id) { 42 }

  before do
    ActiveRecord::Relation.prepend(described_class)

    Gitlab::Database::DataIsolation.configure do |config|
      config.current_sharding_key_value = ->(_sk) { organization_id }
      config.sharding_key_map = SHARDING_KEY_MAP
      config.strategy = :arel
    end
  end

  describe '#arel' do
    context 'when sharding key scope should not be applied' do
      context 'when scoping is disabled' do
        it 'returns original arel without modifications' do
          Gitlab::Database::DataIsolation::Context.without_data_isolation do
            expect(Project.all.to_sql).to eq('SELECT "projects".* FROM "projects"')
          end
        end
      end

      context 'when current_sharding_key_value returns nil' do
        before do
          Gitlab::Database::DataIsolation.configure do |config|
            config.current_sharding_key_value = ->(_sk) { nil }
            config.sharding_key_map = SHARDING_KEY_MAP
          end
        end

        it 'returns original arel without modifications' do
          expect(Project.all.to_sql).to eq('SELECT "projects".* FROM "projects"')
        end
      end

      context 'when table is not in sharding_key_map' do
        it 'returns original arel without modifications' do
          expect(UserDetail.all.to_sql).to eq('SELECT "user_details".* FROM "user_details"')
        end
      end

      context 'when sharding_key_map is empty' do
        before do
          Gitlab::Database::DataIsolation.configure do |config|
            config.current_sharding_key_value = ->(_sk) { organization_id }
            config.sharding_key_map = {}
          end
        end

        it 'returns original arel without modifications' do
          expect(Project.all.to_sql).to eq('SELECT "projects".* FROM "projects"')
        end
      end

      context 'when table is not in the map' do
        it 'does not apply scope to features table' do
          expect(Feature.all.to_sql).to eq('SELECT "features".* FROM "features"')
        end

        it 'does not apply scope to organizations table' do
          expect(Organization.all.to_sql).to eq('SELECT "organizations".* FROM "organizations"')
        end
      end
    end

    context 'when sharding key scope should be applied' do
      it 'adds sharding key scope to the query' do
        expect(Project.all.to_sql).to eq(
          "SELECT \"projects\".* FROM \"projects\" WHERE \"projects\".\"organization_id\" = #{organization_id}"
        )
      end
    end
  end
end
