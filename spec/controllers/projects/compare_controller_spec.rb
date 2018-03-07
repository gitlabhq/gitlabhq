require 'spec_helper'

describe Projects::CompareController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:ref_from) { "improve%2Fawesome" }
  let(:ref_to) { "feature" }

  before do
    sign_in(user)
    project.add_master(user)
  end

  it 'compare shows some diffs' do
    get(:show,
        namespace_id: project.namespace,
        project_id: project,
        from: ref_from,
        to: ref_to)

    expect(response).to be_success
    expect(assigns(:diffs).diff_files.first).not_to be_nil
    expect(assigns(:commits).length).to be >= 1
  end

  it 'compare shows some diffs with ignore whitespace change option' do
    get(:show,
        namespace_id: project.namespace,
        project_id: project,
        from: '08f22f25',
        to: '66eceea0',
        w: 1)

    expect(response).to be_success
    diff_file = assigns(:diffs).diff_files.first
    expect(diff_file).not_to be_nil
    expect(assigns(:commits).length).to be >= 1
    # without whitespace option, there are more than 2 diff_splits
    diff_splits = diff_file.diff.diff.split("\n")
    expect(diff_splits.length).to be <= 2
  end

  describe 'non-existent refs' do
    it 'uses invalid source ref' do
      get(:show,
          namespace_id: project.namespace,
          project_id: project,
          from: 'non-existent',
          to: ref_to)

      expect(response).to be_success
      expect(assigns(:diffs).diff_files.to_a).to eq([])
      expect(assigns(:commits)).to eq([])
    end

    it 'uses invalid target ref' do
      get(:show,
          namespace_id: project.namespace,
          project_id: project,
          from: ref_from,
          to: 'non-existent')

      expect(response).to be_success
      expect(assigns(:diffs)).to eq(nil)
      expect(assigns(:commits)).to eq(nil)
    end

    it 'redirects back to index when params[:from] is empty and preserves params[:to]' do
      post(:create,
           namespace_id: project.namespace,
           project_id: project,
           from: '',
           to: 'master')

      expect(response).to redirect_to(project_compare_index_path(project, to: 'master'))
    end

    it 'redirects back to index when params[:to] is empty and preserves params[:from]' do
      post(:create,
           namespace_id: project.namespace,
           project_id: project,
           from: 'master',
           to: '')

      expect(response).to redirect_to(project_compare_index_path(project, from: 'master'))
    end

    it 'redirects back to index when params[:from] and params[:to] are empty' do
      post(:create,
           namespace_id: project.namespace,
           project_id: project,
           from: '',
           to: '')

      expect(response).to redirect_to(namespace_project_compare_index_path)
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :diff_for_path, params.merge(extra_params)
    end

    let(:existing_path) { 'files/ruby/feature.rb' }

    context 'when the from and to refs exist' do
      context 'when the user has access to the project' do
        context 'when the path exists in the diff' do
          it 'disables diff notes' do
            diff_for_path(from: ref_from, to: ref_to, old_path: existing_path, new_path: existing_path)

            expect(assigns(:diff_notes_disabled)).to be_truthy
          end

          it 'only renders the diffs for the path given' do
            expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
              expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
              meth.call(diffs)
            end

            diff_for_path(from: ref_from, to: ref_to, old_path: existing_path, new_path: existing_path)
          end
        end

        context 'when the path does not exist in the diff' do
          before do
            diff_for_path(from: ref_from, to: ref_to, old_path: existing_path.succ, new_path: existing_path.succ)
          end

          it 'returns a 404' do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when the user does not have access to the project' do
        before do
          project.team.truncate
          diff_for_path(from: ref_from, to: ref_to, old_path: existing_path, new_path: existing_path)
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when the from ref does not exist' do
      before do
        diff_for_path(from: ref_from.succ, to: ref_to, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the to ref does not exist' do
      before do
        diff_for_path(from: ref_from, to: ref_to.succ, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
