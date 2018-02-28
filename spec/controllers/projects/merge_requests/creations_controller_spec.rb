require 'spec_helper'

describe Projects::MergeRequests::CreationsController do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }
  let(:fork_project) { create(:forked_project_with_submodules) }

  before do
    fork_project.add_master(user)

    sign_in(user)
  end

  describe 'GET new' do
    context 'merge request that removes a submodule' do
      render_views

      it 'renders new merge request widget template' do
        get :new,
            namespace_id: fork_project.namespace.to_param,
            project_id: fork_project,
            merge_request: {
              source_branch: 'remove-submodule',
              target_branch: 'master'
            }

        expect(response).to be_success
      end
    end
  end

  describe 'GET pipelines' do
    before do
      create(:ci_pipeline, sha: fork_project.commit('remove-submodule').id,
                           ref: 'remove-submodule',
                           project: fork_project)
    end

    it 'renders JSON including serialized pipelines' do
      get :pipelines,
          namespace_id: fork_project.namespace.to_param,
          project_id: fork_project,
          merge_request: {
            source_branch: 'remove-submodule',
            target_branch: 'master'
          },
          format: :json

      expect(response).to be_ok
      expect(json_response).to have_key 'pipelines'
      expect(json_response['pipelines']).not_to be_empty
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        format: 'json'
      }

      get :diff_for_path, params.merge(extra_params)
    end

    let(:existing_path) { 'files/ruby/feature.rb' }

    context 'when both branches are in the same project' do
      it 'disables diff notes' do
        diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_branch: 'feature', target_branch: 'master' })

        expect(assigns(:diff_notes_disabled)).to be_truthy
      end

      it 'only renders the diffs for the path given' do
        expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
          expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
          meth.call(diffs)
        end

        diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_branch: 'feature', target_branch: 'master' })
      end
    end

    context 'when the source branch is in a different project to the target' do
      let(:other_project) { create(:project, :repository) }

      before do
        other_project.add_master(user)
      end

      context 'when the path exists in the diff' do
        it 'disables diff notes' do
          diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })

          expect(assigns(:diff_notes_disabled)).to be_truthy
        end

        it 'only renders the diffs for the path given' do
          expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
            expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
            meth.call(diffs)
          end

          diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })
        end
      end

      context 'when the path does not exist in the diff' do
        before do
          diff_for_path(old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb', merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
