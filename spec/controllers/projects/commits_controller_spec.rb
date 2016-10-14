require 'spec_helper'

describe Projects::CommitsController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe "GET show" do
    context "when the ref name ends in .atom" do
      render_views

      context "when the ref does not exist with the suffix" do
        it "renders as atom" do
          get(:show,
              namespace_id: project.namespace.to_param,
              project_id: project.to_param,
              id: "master.atom")

          expect(response).to be_success
          expect(response.content_type).to eq('application/atom+xml')
        end
      end

      context "when the ref exists with the suffix" do
        before do
          commit = project.repository.commit('master')

          allow_any_instance_of(Repository).to receive(:commit).and_call_original
          allow_any_instance_of(Repository).to receive(:commit).with('master.atom').and_return(commit)

          get(:show,
              namespace_id: project.namespace.to_param,
              project_id: project.to_param,
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
