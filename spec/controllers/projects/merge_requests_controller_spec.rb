require 'spec_helper'

describe Projects::MergeRequestsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe "#show" do
    shared_examples "export merge as" do |format|
      it "should generally work" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response).to be_success
      end

      it "should generate it" do
        expect_any_instance_of(MergeRequest).to receive(:"to_#{format}")

        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)
      end

      it "should render it" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response.body).to eq((merge_request.send(:"to_#{format}",user)).to_s)
      end

      it "should not escape Html" do
        allow_any_instance_of(MergeRequest).to receive(:"to_#{format}").
          and_return('HTML entities &<>" ')

        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response.body).not_to include('&amp;')
        expect(response.body).not_to include('&gt;')
        expect(response.body).not_to include('&lt;')
        expect(response.body).not_to include('&quot;')
      end
    end

    describe "as diff" do
      include_examples "export merge as", :diff
      let(:format) { :diff }

      it "should really only be a git diff" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response.body).to start_with("diff --git")
      end
    end

    describe "as patch" do
      include_examples "export merge as", :patch
      let(:format) { :patch }

      it "should really be a git email patch with commit" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid, format: format)

        expect(response.body[0..100]).to start_with("From #{merge_request.commits.last.id}")
      end

      it "should contain git diffs" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response.body).to match(/^diff --git/)
      end
    end
  end

  describe 'GET diffs' do
    def go(format: 'html')
      get :diffs,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: merge_request.iid,
          format: format
    end

    context 'as html' do
      it 'renders the diff template' do
        go

        expect(response).to render_template('diffs')
      end
    end

    context 'as json' do
      it 'renders the diffs template to a string' do
        go format: 'json'

        expect(response).to render_template('projects/merge_requests/show/_diffs')
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end

    context 'with forked projects with submodules' do
      render_views

      let(:project) { create(:project) }
      let(:fork_project) { create(:forked_project_with_submodules) }
      let(:merge_request) { create(:merge_request_with_diffs, source_project: fork_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

      before do
        fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
        fork_project.save
        merge_request.reload
      end

      it 'renders' do
        go format: 'json'

        expect(response).to be_success
        expect(response.body).to have_content('Subproject commit')
      end
    end
  end

  describe 'GET diffs with ignore_whitespace_change' do
    def go(format: 'html')
      get :diffs,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: merge_request.iid,
          format: format,
          w: 1
    end

    context 'as html' do
      it 'renders the diff template' do
        go

        expect(response).to render_template('diffs')
      end
    end
    
    context 'as json' do
      it 'renders the diffs template to a string' do
        go format: 'json'

        expect(response).to render_template('projects/merge_requests/show/_diffs')
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end
  end

  describe 'GET commits' do
    def go(format: 'html')
      get :commits,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: merge_request.iid,
          format: format
    end

    context 'as html' do
      it 'renders the show template' do
        go

        expect(response).to render_template('show')
      end
    end

    context 'as json' do
      it 'renders the commits template to a string' do
        go format: 'json'

        expect(response).to render_template('projects/merge_requests/show/_commits')
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end
  end
end
