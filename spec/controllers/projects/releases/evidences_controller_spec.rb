# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Releases::EvidencesController do
  let!(:project) { create(:project, :repository, :public) }
  let_it_be(:private_project) { create(:project, :repository, :private) }
  let_it_be(:developer)  { create(:user) }
  let_it_be(:reporter)   { create(:user) }

  let(:user)             { developer }

  before do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  shared_examples_for 'successful request' do
    it 'renders a 200' do
      subject

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  shared_examples_for 'not found' do
    it 'renders 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let(:tag_name) { "v1.1.0-evidence" }
    let!(:release) { create(:release, project: project, tag: tag_name) }
    let(:evidence) { release.evidences.first }
    let(:tag) { CGI.escape(release.tag) }
    let(:format) { :json }

    subject do
      get :show, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        tag: tag,
        id: evidence.id,
        format: format
      }
    end

    before do
      ::Releases::CreateEvidenceService.new(release).execute

      sign_in(user)
    end

    context 'when the user is a developer' do
      it 'returns the correct evidence summary as a json' do
        subject

        expect(json_response).to eq(evidence.summary)
      end

      context 'when the release was created before evidence existed' do
        before do
          evidence.destroy!
        end

        it_behaves_like 'not found'
      end
    end

    context 'when the user is a guest for the project' do
      before do
        project.add_guest(user)
      end

      context 'when the project is private' do
        let(:project) { private_project }

        it_behaves_like 'not found'
      end

      context 'when the project is public' do
        it_behaves_like 'successful request'
      end
    end

    context 'when release is associated to a milestone which includes an issue' do
      let(:issue) { create(:issue, project: project) }
      let(:milestone) { create(:milestone, project: project, issues: [issue]) }
      let(:release) { create(:release, project: project, tag: tag_name, milestones: [milestone]) }

      shared_examples_for 'does not show the issue in evidence' do
        it do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['release']['milestones']
            .all? { |milestone| milestone['issues'].nil? }).to eq(true)
        end
      end

      shared_examples_for 'evidence not found' do
        it do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is non-project member' do
        let(:user) { create(:user) }

        it_behaves_like 'does not show the issue in evidence'

        context 'when project is private' do
          let(:project) { create(:project, :repository, :private) }

          it_behaves_like 'evidence not found'
        end

        context 'when project restricts the visibility of issues to project members only' do
          let(:project) { create(:project, :repository, :issues_private) }

          it_behaves_like 'evidence not found'
        end
      end

      context 'when user is auditor', if: Gitlab.ee? do
        let(:user) { create(:user, :auditor) }

        it_behaves_like 'does not show the issue in evidence'

        context 'when project is private' do
          let(:project) { create(:project, :repository, :private) }

          it_behaves_like 'does not show the issue in evidence'
        end

        context 'when project restricts the visibility of issues to project members only' do
          let(:project) { create(:project, :repository, :issues_private) }

          it_behaves_like 'does not show the issue in evidence'
        end
      end

      context 'when external authorization control is enabled' do
        let(:user) { create(:user) }

        before do
          stub_application_setting(external_authorization_service_enabled: true)
        end

        it_behaves_like 'evidence not found'
      end
    end
  end
end
