# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ImportsFinder, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:started_import) { create(:bulk_import, :started, user: user) }
  let_it_be(:finished_import) { create(:bulk_import, :finished, user: user) }
  let_it_be(:not_user_import) { create(:bulk_import) }

  subject { described_class.new(user: user) }

  describe '#execute' do
    it 'returns a list of imports associated with user' do
      expect(subject.execute).to contain_exactly(started_import, finished_import)
    end

    context 'when status is specified' do
      subject { described_class.new(user: user, params: { status: 'started' }) }

      it 'returns a list of import entities filtered by status' do
        expect(subject.execute).to contain_exactly(started_import)
      end

      context 'when invalid status is specified' do
        subject { described_class.new(user: user, params: { status: 'invalid' }) }

        it 'does not filter entities by status' do
          expect(subject.execute).to contain_exactly(started_import, finished_import)
        end
      end
    end

    context 'when order is specified' do
      subject { described_class.new(user: user, params: { sort: order }) }

      context 'when order is specified as asc' do
        let(:order) { :asc }

        it 'returns entities sorted ascending' do
          expect(subject.execute).to eq([started_import, finished_import])
        end
      end

      context 'when order is specified as desc' do
        let(:order) { :desc }

        it 'returns entities sorted descending' do
          expect(subject.execute).to eq([finished_import, started_import])
        end
      end
    end

    context 'when configuration is included' do
      it 'preloads configuration association' do
        imports = described_class
          .new(user: user, params: { include_configuration: true })
          .execute

        expect(imports.first.association_cached?(:configuration)).to be(true)
      end
    end
  end
end
