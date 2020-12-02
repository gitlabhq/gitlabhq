# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitsController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
  end

  context 'signed in' do
    before do
      sign_in(user)
    end

    describe "GET commits_root" do
      context "no ref is provided" do
        it 'redirects to the default branch of the project' do
          get(:commits_root,
              params: {
                namespace_id: project.namespace,
                project_id: project
              })

          expect(response).to redirect_to project_commits_path(project)
        end
      end
    end

    describe "GET show" do
      render_views

      context 'with file path' do
        before do
          get(:show,
              params: {
                namespace_id: project.namespace,
                project_id: project,
                id: id
              })
        end

        context "valid branch, valid file" do
          let(:id) { 'master/README.md' }

          it { is_expected.to respond_with(:success) }
        end

        context "valid branch, invalid file" do
          let(:id) { 'master/invalid-path.rb' }

          it { is_expected.to respond_with(:not_found) }
        end

        context "invalid branch, valid file" do
          let(:id) { 'invalid-branch/README.md' }

          it { is_expected.to respond_with(:not_found) }
        end

        context "branch with invalid format, valid file" do
          let(:id) { 'branch with space/README.md' }

          it { is_expected.to respond_with(:not_found) }
        end
      end

      context "when the ref name ends in .atom" do
        context "when the ref does not exist with the suffix" do
          before do
            get(:show,
                params: {
                  namespace_id: project.namespace,
                  project_id: project,
                  id: "master.atom"
                })
          end

          it "renders as atom" do
            expect(response).to be_successful
            expect(response.media_type).to eq('application/atom+xml')
          end

          it 'renders summary with type=html' do
            expect(response.body).to include('<summary type="html">')
          end
        end

        context "when the ref exists with the suffix" do
          before do
            commit = project.repository.commit('master')

            allow_any_instance_of(Repository).to receive(:commit).and_call_original
            allow_any_instance_of(Repository).to receive(:commit).with('master.atom').and_return(commit)

            get(:show,
                params: {
                  namespace_id: project.namespace,
                  project_id: project,
                  id: "master.atom"
                })
          end

          it "renders as HTML" do
            expect(response).to be_successful
            expect(response.media_type).to eq('text/html')
          end
        end
      end
    end

    describe "GET /commits/:id/signatures" do
      render_views

      before do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original unless id.include?(' ')

        get(:signatures,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              id: id
            },
            format: :json)
      end

      context "valid branch" do
        let(:id) { 'master' }

        it { is_expected.to respond_with(:success) }
      end

      context "invalid branch format" do
        let(:id) { 'some branch' }

        it { is_expected.to respond_with(:not_found) }
      end
    end
  end

  context 'token authentication' do
    context 'public project' do
      it_behaves_like 'authenticates sessionless user', :show, :atom, { public: true, ignore_incrementing: true } do
        before do
          public_project = create(:project, :repository, :public)

          default_params.merge!(namespace_id: public_project.namespace, project_id: public_project, id: "master.atom")
        end
      end
    end

    context 'private project' do
      it_behaves_like 'authenticates sessionless user', :show, :atom, { public: false, ignore_incrementing: true } do
        before do
          private_project = create(:project, :repository, :private)
          private_project.add_maintainer(user)

          default_params.merge!(namespace_id: private_project.namespace, project_id: private_project, id: "master.atom")
        end
      end
    end
  end
end
