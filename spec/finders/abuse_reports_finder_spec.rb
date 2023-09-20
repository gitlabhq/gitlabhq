# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportsFinder, feature_category: :insider_threat do
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }

  let_it_be(:reporter_1) { create(:user) }
  let_it_be(:reporter_2) { create(:user) }

  let_it_be(:abuse_report_1) do
    create(:abuse_report, :open, category: 'spam', user: user_1, reporter: reporter_1, id: 1)
  end

  let_it_be(:abuse_report_2) do
    create(:abuse_report, :closed, category: 'phishing', user: user_2, reporter: reporter_2, id: 2)
  end

  subject(:finder) { described_class.new(params).execute }

  describe '#execute' do
    shared_examples 'returns all abuse reports' do
      it 'returns all abuse reports' do
        expect(finder).to match_array([abuse_report_1, abuse_report_2])
      end
    end

    context 'when params is empty' do
      let(:params) { {} }

      it_behaves_like 'returns all abuse reports'
    end

    shared_examples 'returns filtered reports' do |filter_field|
      it "returns abuse reports filtered by #{filter_field}_id" do
        expect(finder).to match_array(filtered_reports)
      end

      context "when no user has username = params[:#{filter_field}]" do
        before do
          allow(User).to receive_message_chain(:by_username, :pick)
            .with(params[filter_field])
            .with(:id)
            .and_return(nil)
        end

        it_behaves_like 'returns all abuse reports'
      end
    end

    context 'when params[:user] is present' do
      it_behaves_like 'returns filtered reports', :user do
        let(:params) { { user: user_1.username } }
        let(:filtered_reports) { [abuse_report_1] }
      end
    end

    context 'when params[:reporter] is present' do
      it_behaves_like 'returns filtered reports', :reporter do
        let(:params) { { reporter: reporter_1.username } }
        let(:filtered_reports) { [abuse_report_1] }
      end
    end

    context 'when params[:status] = open' do
      let(:params) { { status: 'open' } }

      it 'returns only open abuse reports' do
        expect(finder).to match_array([abuse_report_1])
      end
    end

    context 'when params[:status] = closed' do
      let(:params) { { status: 'closed' } }

      it 'returns only closed abuse reports' do
        expect(finder).to match_array([abuse_report_2])
      end
    end

    context 'when params[:status] is not a valid status' do
      let(:params) { { status: 'partial' } }

      it 'defaults to returning open abuse reports' do
        expect(finder).to match_array([abuse_report_1])
      end
    end

    context 'when params[:category] is present' do
      let(:params) { { category: 'phishing' } }

      it 'returns abuse reports with the specified category' do
        expect(subject).to match_array([abuse_report_2])
      end
    end

    describe 'aggregating reports' do
      context 'when multiple open reports exist' do
        let(:params) { { status: 'open' } }

        # same category and user as abuse_report_1 -> will get aggregated
        let_it_be(:abuse_report_3) do
          create(:abuse_report, :open, category: abuse_report_1.category, user: abuse_report_1.user, id: 3)
        end

        # different category, but same user as abuse_report_1 -> won't get aggregated
        let_it_be(:abuse_report_4) do
          create(:abuse_report, :open, category: 'phishing', user: abuse_report_1.user, id: 4)
        end

        it 'aggregates open reports by user and category' do
          expect(finder).to match_array([abuse_report_1, abuse_report_4])
        end

        it 'sorts by aggregated_count in descending order and created_at in descending order' do
          expect(finder).to eq([abuse_report_1, abuse_report_4])
        end

        it 'returns count with aggregated reports' do
          expect(finder[0].count).to eq(2)
        end

        context 'when a different sorting attribute is given' do
          let(:params) { { status: 'open', sort: 'created_at_desc' } }

          it 'returns reports sorted by the specified sort attribute' do
            expect(subject).to eq([abuse_report_4, abuse_report_1])
          end
        end

        context 'when params[:sort] is invalid' do
          let(:params) { { status: 'open', sort: 'invalid' } }

          it 'sorts reports by aggregated_count in descending order' do
            expect(finder).to eq([abuse_report_1, abuse_report_4])
          end
        end
      end

      context 'when multiple closed reports exist' do
        let(:params) { { status: 'closed' } }

        # same user and category as abuse_report_2 -> won't get aggregated
        let_it_be(:abuse_report_5) do
          create(:abuse_report, :closed, category: abuse_report_2.category, user: abuse_report_2.user, id: 5)
        end

        it 'does not aggregate closed reports' do
          expect(finder).to match_array([abuse_report_2, abuse_report_5])
        end

        it 'sorts reports by created_at in descending order' do
          expect(finder).to eq([abuse_report_5, abuse_report_2])
        end

        context 'when a different sorting attribute is given' do
          let(:params) { { status: 'closed', sort: 'created_at_asc' } }

          it 'returns reports sorted by the specified sort attribute' do
            expect(subject).to eq([abuse_report_2, abuse_report_5])
          end
        end

        context 'when params[:sort] is invalid' do
          let(:params) { { status: 'closed', sort: 'invalid' } }

          it 'sorts reports by created_at in descending order' do
            expect(finder).to eq([abuse_report_5, abuse_report_2])
          end
        end
      end
    end
  end
end
