# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SnippetsController do
  include Gitlab::Routing

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }

  before do
    project.add_maintainer(user)
    project.add_developer(other_user)
  end

  describe 'GET #index' do
    let(:base_params) do
      {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    subject { get :index, params: base_params }

    it_behaves_like 'paginated collection' do
      let(:collection) { project.snippets }
      let(:params) { base_params }

      before do
        create(:project_snippet, :public, project: project, author: user)
      end
    end

    it 'fetches snippet counts via the snippet count service' do
      service = double(:count_service, execute: {})
      expect(Snippets::CountService)
        .to receive(:new).with(nil, project: project)
        .and_return(service)

      subject
    end

    it_behaves_like 'snippets sort order' do
      let(:params) { base_params }
    end

    it_behaves_like 'snippets views' do
      let(:params) { base_params }
    end

    context 'when the project snippet is private' do
      let_it_be(:project_snippet) { create(:project_snippet, :private, project: project, author: user) }

      context 'when anonymous' do
        it 'does not include the private snippet' do
          subject

          expect(assigns(:snippets)).not_to include(project_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when signed in as the author' do
        it 'renders the snippet' do
          sign_in(user)

          subject

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when signed in as a project member' do
        it 'renders the snippet' do
          sign_in(other_user)

          subject

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST #mark_as_spam' do
    let_it_be(:snippet) { create(:project_snippet, :private, project: project, author: user) }

    before do
      allow_next_instance_of(Spam::AkismetService) do |instance|
        allow(instance).to receive_messages(submit_spam: true)
      end
      stub_application_setting(akismet_enabled: true)
    end

    def mark_as_spam
      admin = create(:admin)
      create(:user_agent_detail, subject: snippet)
      project.add_maintainer(admin)
      sign_in(admin)

      post :mark_as_spam, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: snippet.id
      }
    end

    it 'updates the snippet', :enable_admin_mode do
      mark_as_spam

      expect(snippet.reload).not_to be_submittable_as_spam
    end
  end

  shared_examples 'successful response' do
    it 'renders the snippet' do
      subject

      expect(assigns(:snippet)).to eq(project_snippet)
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  %w[show raw].each do |action|
    describe "GET ##{action}" do
      context 'when the project snippet is private' do
        let_it_be(:project_snippet) { create(:project_snippet, :private, :repository, project: project, author: user) }

        subject { get action, params: { namespace_id: project.namespace, project_id: project, id: project_snippet.to_param } }

        context 'when anonymous' do
          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when signed in as the author' do
          before do
            sign_in(user)
          end

          it_behaves_like 'successful response'
        end

        context 'when signed in as a project member' do
          before do
            sign_in(other_user)
          end

          it_behaves_like 'successful response'
        end
      end

      context 'when the project snippet does not exist' do
        subject { get action, params: { namespace_id: project.namespace, project_id: project, id: 42 } }

        context 'when anonymous' do
          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when signed in' do
          before do
            sign_in(user)
          end

          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when the project snippet is public' do
        let_it_be(:project_snippet_public) { create(:project_snippet, :public, :repository, project: project, author: user) }

        context 'when attempting to access from a different project route' do
          subject { get action, params: { namespace_id: project.namespace, project_id: 42, id: project_snippet_public.to_param } }

          before do
            sign_in(user)
          end

          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe "GET #show for embeddable content" do
    let(:project_snippet) { create(:project_snippet, :repository, snippet_permission, project: project, author: user) }
    let(:extra_params) { {} }

    before do
      sign_in(user)
    end

    subject { get :show, params: { namespace_id: project.namespace, project_id: project, id: project_snippet.to_param, **extra_params }, format: :js }

    context 'when snippet is private' do
      let(:snippet_permission) { :private }

      it 'responds with status 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when snippet is public' do
      let(:snippet_permission) { :public }

      it 'renders the blob from the repository' do
        subject

        expect(assigns(:snippet)).to eq(project_snippet)
        expect(assigns(:blobs).map(&:name)).to eq(project_snippet.blobs.map(&:name))
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not show the blobs expanded by default' do
        subject

        expect(assigns(:blobs).map(&:expanded?)).to be_all(false)
      end

      context 'when param expanded is set' do
        let(:extra_params) { { expanded: true } }

        it 'shows all blobs expanded' do
          subject

          expect(assigns(:blobs).map(&:expanded?)).to be_all(true)
        end
      end
    end

    context 'when the project is private' do
      let(:project) { create(:project_empty_repo, :private) }

      context 'when snippet is public' do
        let(:project_snippet) { create(:project_snippet, :public, project: project, author: user) }

        it 'responds with status 404' do
          subject

          expect(assigns(:snippet)).to eq(project_snippet)
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET #raw' do
    let(:inline) { nil }
    let(:line_ending) { nil }
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: project_snippet.to_param,
        inline: inline,
        line_ending: line_ending
      }
    end

    subject { get :raw, params: params }

    context 'when repository is empty' do
      let_it_be(:content) { "first line\r\nsecond line\r\nthird line" }
      let_it_be(:project_snippet) do
        create(
          :project_snippet, :public, :empty_repo,
          project: project,
          author: user,
          content: content
        )
      end

      let(:formatted_content) { content.gsub(/\r\n/, "\n") }

      context 'CRLF line ending' do
        before do
          allow_next_instance_of(Blob) do |instance|
            allow(instance).to receive(:data).and_return(content)
          end
        end

        it 'returns LF line endings by default' do
          subject

          expect(response.body).to eq(formatted_content)
        end

        context 'when line_ending parameter present' do
          let(:line_ending) { :raw }

          it 'does not convert line endings' do
            subject

            expect(response.body).to eq(content)
          end
        end
      end
    end

    context 'when repository is not empty' do
      let_it_be(:project_snippet) do
        create(
          :project_snippet, :public, :repository,
          project: project,
          author: user
        )
      end

      it 'sends the blob' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
      end

      it_behaves_like 'project cache control headers'
      it_behaves_like 'content disposition headers'

      context 'when user is logged in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'project cache control headers'
      end
    end
  end
end
