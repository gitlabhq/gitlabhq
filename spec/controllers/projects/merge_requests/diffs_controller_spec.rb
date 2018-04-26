require 'spec_helper'

describe Projects::MergeRequests::DiffsController do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        format: 'json'
      }

      get :show, params.merge(extra_params)
    end

    context 'with default params' do
      context 'for the same project' do
        before do
          allow(controller).to receive(:rendered_for_merge_request?).and_return(true)
        end

        it 'serializes merge request diff collection' do
          expect_any_instance_of(DiffsSerializer).to receive(:represent).with(an_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff), an_instance_of(Hash))

          go
        end
      end

      context 'with forked projects with submodules' do
        render_views

        let(:project) { create(:project, :repository) }
        let(:forked_project) { fork_project_with_submodules(project) }
        let(:merge_request) { create(:merge_request_with_diffs, source_project: forked_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

        before do
          project.add_developer(user)

          merge_request.reload
          go
        end

        it 'renders' do
          expect(response).to be_success
          expect(response.body).to have_content('Subproject commit')
        end
      end
    end

    context 'with view' do
      before do
        go(view: 'parallel')
      end

      it 'saves the preferred diff view in a cookie' do
        expect(response.cookies['diff_view']).to eq('parallel')
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        format: 'json'
      }

      get :diff_for_path, params.merge(extra_params)
    end

    let(:existing_path) { 'files/ruby/popen.rb' }

    context 'when the merge request exists' do
      context 'when the user can view the merge request' do
        context 'when the path exists in the diff' do
          it 'enables diff notes' do
            diff_for_path(old_path: existing_path, new_path: existing_path)

            expect(assigns(:diff_notes_disabled)).to be_falsey
            expect(assigns(:new_diff_note_attrs)).to eq(noteable_type: 'MergeRequest',
                                                        noteable_id: merge_request.id,
                                                        commit_id: nil)
          end

          it 'only renders the diffs for the path given' do
            expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
              expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
              meth.call(diffs)
            end

            diff_for_path(old_path: existing_path, new_path: existing_path)
          end
        end

        context 'when the path does not exist in the diff' do
          before do
            diff_for_path(old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb')
          end

          it 'returns a 404' do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when the user cannot view the merge request' do
        before do
          project.team.truncate
          diff_for_path(old_path: existing_path, new_path: existing_path)
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when the merge request does not exist' do
      before do
        diff_for_path(id: merge_request.iid.succ, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the merge request belongs to a different project' do
      let(:other_project) { create(:project) }

      before do
        other_project.add_master(user)
        diff_for_path(old_path: existing_path, new_path: existing_path, project_id: other_project)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
