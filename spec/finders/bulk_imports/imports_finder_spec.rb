# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ImportsFinder do
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
      subject { described_class.new(user: user, status: 'started') }

      it 'returns a list of import entities filtered by status' do
        expect(subject.execute).to contain_exactly(started_import)
      end

      context 'when invalid status is specified' do
        subject { described_class.new(user: user, status: 'invalid') }

        it 'does not filter entities by status' do
          expect(subject.execute).to contain_exactly(started_import, finished_import)
        end
      end
    end
  end
end
