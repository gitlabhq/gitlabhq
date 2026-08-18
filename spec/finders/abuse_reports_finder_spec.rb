# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportsFinder, feature_category: :insider_threat do
  # `create(:user)` assigns `create(:common_organization)` when no organization is given, and
  # :common_organization is a find_or_create_by! singleton. Every bare `create(:user)` below
  # therefore shares this organization, as does every report built from one.
  let_it_be(:common_organization) { create(:common_organization) }

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

  let(:organization) { common_organization }

  subject(:finder) { described_class.new(params, organization: organization).execute }

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

    describe 'organization isolation' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:other_org_reporter) { create(:user, organization: other_organization) }
      let_it_be(:cross_org_user) { create(:user) }

      # The open list groups reports by (user, category) and shows one report per group: the one
      # with the smallest id. This report is in the same group as current_org_report below, and
      # deliberately has the smaller id of the two.
      #
      # So if the grouping step ever stops filtering by organization, this report represents the
      # group, and is then dropped by the organization filter that runs after it. The result is
      # that current_org_report disappears from the list. A row going missing is a much louder
      # failure than an extra row showing up.
      #
      # Only the relative order of the two ids matters, never their absolute values, so they are
      # derived from the fixtures above rather than hardcoded.
      let_it_be(:other_org_report) do
        create(:abuse_report, :open, id: abuse_report_2.id + 1, category: 'spam', user: cross_org_user,
          reporter: other_org_reporter, organization: other_organization)
      end

      let_it_be(:current_org_report) do
        create(:abuse_report, :open, id: abuse_report_2.id + 2, category: 'spam', user: cross_org_user)
      end

      context 'when params is empty' do
        let(:params) { {} }

        it 'excludes reports belonging to another organization' do
          expect(finder).to match_array([abuse_report_1, abuse_report_2, current_org_report])
        end
      end

      context 'when params[:status] = open' do
        let(:params) { { status: 'open' } }

        it 'excludes other organizations from the results and from the aggregation',
          :aggregate_failures do
          expect(finder).to match_array([abuse_report_1, current_org_report])

          # Two reports exist globally for (cross_org_user, spam); only one is in this organization.
          expect(finder.find { |report| report.id == current_org_report.id }.count).to eq(1)
        end
      end

      context 'when scoped to the other organization' do
        let(:params) { {} }
        let(:organization) { other_organization }

        it 'returns only that organization reports' do
          expect(finder).to contain_exactly(other_org_report)
        end
      end

      context 'when filtering by a reporter that only exists in another organization' do
        let(:params) { { reporter: other_org_reporter.username } }

        it 'returns no reports' do
          expect(finder).to be_empty
        end
      end
    end
  end
end
