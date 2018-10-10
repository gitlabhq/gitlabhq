require 'spec_helper'

describe Groups::Security::VulnerabilitiesController do
  include ApiHelpers

  set(:group) { create(:group) }
  set(:group_other) { create(:group) }
  set(:user) { create(:user) }
  set(:project_dev) { create(:project, :private, :repository, group: group) }
  set(:project_guest) { create(:project, :private, :repository, group: group) }
  set(:project_other) { create(:project, :public, :repository, group: group_other) }
  let(:projects) { [project_dev, project_guest, project_other] }

  before do
    sign_in(user)
  end

  describe 'GET index.json' do
    subject { get :index, group_id: group, format: :json }

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user has guest access' do
        before do
          group.add_guest(user)
        end

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user has developer access' do
        before do
          group.add_developer(user)
        end

        context 'when no page request' do
          before do
            projects.each do |project|
              create(:vulnerabilities_occurrence, project: project)
            end
          end

          it "returns a list of vulnerabilities" do
            subject

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 2
            expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
          end
        end

        context 'when page requested' do
          before do
            projects.each do |project|
              create_list(:vulnerabilities_occurrence, 11, project: project)
            end
          end

          it "returns a list of vulnerabilities" do
            get :index, group_id: group, page: 3, format: :json

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 2
          end
        end

        context 'with vulnerability feedback' do
          def get_summary
            get :index, group_id: group, format: :json
          end

          it "avoids N+1 queries" do
            control_count = ActiveRecord::QueryRecorder.new { get_summary }

            # Create feedback
            project_dev.vulnerabilities.each do |occ|
              create(:vulnerability_feedback, :sast, :dismissal,
                     project: project_dev, project_fingerprint: occ.project_fingerprint)

              create(:vulnerability_feedback, :sast, :issue,
                     issue: create(:issue, project: project),
                     project: project_dev, project_fingerprint: occ.project_fingerprint)
            end

            expect { get_summary }.not_to exceed_query_limit(control_count)
          end
        end
      end
    end
  end

  describe 'GET summary.json' do
    subject { get :summary, group_id: group, format: :json }

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)

        create_list(:vulnerabilities_occurrence, 3,
                    project: project_dev, report_type: :sast, severity: :high)

        create_list(:vulnerabilities_occurrence, 1,
                    project: project_dev, report_type: :dependency_scanning, severity: :low)

        create_list(:vulnerabilities_occurrence, 2,
                    project: project_guest, report_type: :dependency_scanning, severity: :low)

        create_list(:vulnerabilities_occurrence, 1,
                    project: project_guest, report_type: :dast, severity: :medium)

        create_list(:vulnerabilities_occurrence, 1,
                    project: project_other, report_type: :dast, severity: :low)
      end

      context 'when user has guest access' do
        before do
          group.add_guest(user)
        end

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user has developer access' do
        before do
          group.add_developer(user)
        end

        it 'returns vulnerabilities counts' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Hash)
          expect(json_response.dig('sast', 'high')).to eq(3)
          expect(json_response.dig('dependency_scanning', 'low')).to eq(3)
          expect(json_response.dig('dast', 'medium')).to eq(1)
          expect(response).to match_response_schema('vulnerabilities/summary', dir: 'ee')
        end
      end
    end
  end
end
