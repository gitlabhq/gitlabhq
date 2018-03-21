require 'spec_helper'

describe Projects::CommitsController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe "GET show" do
    render_views

    context 'with file path' do
      before do
        get(:show,
            namespace_id: project.namespace,
            project_id: project,
            id: id)
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
    end

    context "when the ref name ends in .atom" do
      context "when the ref does not exist with the suffix" do
        before do
          get(:show,
              namespace_id: project.namespace,
              project_id: project,
              id: "master.atom")
        end

        it "renders as atom" do
          expect(response).to be_success
          expect(response.content_type).to eq('application/atom+xml')
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
              namespace_id: project.namespace,
              project_id: project,
              id: "master.atom")
        end

        it "renders as HTML" do
          expect(response).to be_success
          expect(response.content_type).to eq('text/html')
        end
      end
    end
  end
end
