# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportLabelsFinder, feature_category: :insider_threat do
  let_it_be(:current_user) { create(:admin) }
  let_it_be(:project_label) { create(:label) }
  let_it_be(:label_one) { create(:abuse_report_label, title: 'Uno') }
  let_it_be(:label_two) { create(:abuse_report_label, title: 'Dos') }

  let(:params) { {} }

  subject(:finder) { described_class.new(current_user, params) }

  describe '#execute', :enable_admin_mode do
    context 'when current user is admin' do
      context 'when params is empty' do
        it 'returns all abuse report labels sorted by title in ascending order' do
          expect(finder.execute).to eq([label_two, label_one])
        end
      end

      context 'when search_term param is present' do
        let(:params) { { search_term: 'un' } }

        it 'returns matching abuse report labels' do
          expect(finder.execute).to match_array([label_one])
        end
      end
    end

    context 'when current user is not an admin' do
      let_it_be(:current_user) { create(:user) }

      it 'returns nothing' do
        expect(finder.execute).to be_empty
      end
    end
  end
end
