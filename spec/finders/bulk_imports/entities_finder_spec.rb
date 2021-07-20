# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::EntitiesFinder do
  let_it_be(:user) { create(:user) }

  let_it_be(:user_import_1) { create(:bulk_import, user: user) }
  let_it_be(:started_entity_1) { create(:bulk_import_entity, :started, bulk_import: user_import_1) }
  let_it_be(:finished_entity_1) { create(:bulk_import_entity, :finished, bulk_import: user_import_1) }
  let_it_be(:failed_entity_1) { create(:bulk_import_entity, :failed, bulk_import: user_import_1) }

  let_it_be(:user_import_2) { create(:bulk_import, user: user) }
  let_it_be(:started_entity_2) { create(:bulk_import_entity, :started, bulk_import: user_import_2) }
  let_it_be(:finished_entity_2) { create(:bulk_import_entity, :finished, bulk_import: user_import_2) }
  let_it_be(:failed_entity_2) { create(:bulk_import_entity, :failed, bulk_import: user_import_2) }

  let_it_be(:not_user_import) { create(:bulk_import) }
  let_it_be(:started_entity_3) { create(:bulk_import_entity, :started, bulk_import: not_user_import) }
  let_it_be(:finished_entity_3) { create(:bulk_import_entity, :finished, bulk_import: not_user_import) }
  let_it_be(:failed_entity_3) { create(:bulk_import_entity, :failed, bulk_import: not_user_import) }

  subject { described_class.new(user: user) }

  describe '#execute' do
    it 'returns a list of import entities associated with user' do
      expect(subject.execute)
        .to contain_exactly(
          started_entity_1, finished_entity_1, failed_entity_1,
          started_entity_2, finished_entity_2, failed_entity_2
        )
    end

    context 'when bulk import is specified' do
      subject { described_class.new(user: user, bulk_import: user_import_1) }

      it 'returns a list of import entities filtered by bulk import' do
        expect(subject.execute)
          .to contain_exactly(
            started_entity_1, finished_entity_1, failed_entity_1
          )
      end

      context 'when specified import is not associated with user' do
        subject { described_class.new(user: user, bulk_import: not_user_import) }

        it 'does not return entities' do
          expect(subject.execute).to be_empty
        end
      end
    end

    context 'when status is specified' do
      subject { described_class.new(user: user, status: 'failed') }

      it 'returns a list of import entities filtered by status' do
        expect(subject.execute)
          .to contain_exactly(
            failed_entity_1, failed_entity_2
          )
      end

      context 'when invalid status is specified' do
        subject { described_class.new(user: user, status: 'invalid') }

        it 'does not filter entities by status' do
          expect(subject.execute)
            .to contain_exactly(
              started_entity_1, finished_entity_1, failed_entity_1,
              started_entity_2, finished_entity_2, failed_entity_2
            )
        end
      end
    end

    context 'when bulk import and status are specified' do
      subject { described_class.new(user: user, bulk_import: user_import_2, status: 'finished') }

      it 'returns matched import entities' do
        expect(subject.execute).to contain_exactly(finished_entity_2)
      end
    end
  end
end
