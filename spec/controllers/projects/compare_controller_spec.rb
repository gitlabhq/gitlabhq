# frozen_string_literal: true

require 'spec_helper'

describe Projects::CompareController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET index' do
    render_views

    before do
      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    it 'returns successfully' do
      expect(response).to be_success
    end
  end

  describe 'GET show' do
    render_views

    subject(:show_request) { get :show, params: request_params }

    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        from: source_ref,
        to: target_ref,
        w: whitespace
      }
    end

    let(:whitespace) { nil }

    context 'when the refs exist' do
      context 'when we set the white space param' do
        let(:source_ref) { "08f22f25" }
        let(:target_ref) { "66eceea0" }
        let(:whitespace) { 1 }

        it 'shows some diffs with ignore whitespace change option' do
          show_request

          expect(response).to be_success
          diff_file = assigns(:diffs).diff_files.first
          expect(diff_file).not_to be_nil
          expect(assigns(:commits).length).to be >= 1
          # without whitespace option, there are more than 2 diff_splits
          diff_splits = diff_file.diff.diff.split("\n")
          expect(diff_splits.length).to be <= 2
        end
      end

      context 'when we do not set the white space param' do
        let(:source_ref) { "improve%2Fawesome" }
        let(:target_ref) { "feature" }
        let(:whitespace) { nil }

        it 'sets the diffs and commits ivars' do
          show_request

          expect(response).to be_success
          expect(assigns(:diffs).diff_files.first).not_to be_nil
          expect(assigns(:commits).length).to be >= 1
        end
      end
    end

    context 'when the source ref does not exist' do
      let(:source_ref) { 'non-existent-source-ref' }
      let(:target_ref) { "feature" }

      it 'sets empty diff and commit ivars' do
        show_request

        expect(response).to be_success
        expect(assigns(:diffs)).to eq([])
        expect(assigns(:commits)).to eq([])
      end
    end

    context 'when the target ref does not exist' do
      let(:target_ref) { 'non-existent-target-ref' }
      let(:source_ref) { "improve%2Fawesome" }

      it 'sets empty diff and commit ivars' do
        show_request

        expect(response).to be_success
        expect(assigns(:diffs)).to eq([])
        expect(assigns(:commits)).to eq([])
      end
    end

    context 'when the target ref is invalid' do
      let(:target_ref) { "master%' AND 2554=4423 AND '%'='" }
      let(:source_ref) { "improve%2Fawesome" }

      it 'shows a flash message and redirects' do
        show_request

        expect(flash[:alert]).to eq('Invalid branch name')
        expect(response).to have_http_status(302)
      end
    end

    context 'when the source ref is invalid' do
      let(:source_ref) { "master%' AND 2554=4423 AND '%'='" }
      let(:target_ref) { "improve%2Fawesome" }

      it 'shows a flash message and redirects' do
        show_request

        expect(flash[:alert]).to eq('Invalid branch name')
        expect(response).to have_http_status(302)
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :diff_for_path, params: params.merge(extra_params)
    end

    let(:existing_path) { 'files/ruby/feature.rb' }
    let(:source_ref) { "improve%2Fawesome" }
    let(:target_ref) { "feature" }

    context 'when the source and target refs exist' do
      context 'when the user has access target the project' do
        context 'when the path exists in the diff' do
          it 'disables diff notes' do
            diff_for_path(from: source_ref, to: target_ref, old_path: existing_path, new_path: existing_path)

            expect(assigns(:diff_notes_disabled)).to be_truthy
          end

          it 'only renders the diffs for the path given' do
            expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
              expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
              meth.call(diffs)
            end

            diff_for_path(from: source_ref, to: target_ref, old_path: existing_path, new_path: existing_path)
          end
        end

        context 'when the path does not exist in the diff' do
          before do
            diff_for_path(from: source_ref, to: target_ref, old_path: existing_path.succ, new_path: existing_path.succ)
          end

          it 'returns a 404' do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when the user does not have access target the project' do
        before do
          project.team.truncate
          diff_for_path(from: source_ref, to: target_ref, old_path: existing_path, new_path: existing_path)
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when the source ref does not exist' do
      before do
        diff_for_path(from: source_ref.succ, to: target_ref, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the target ref does not exist' do
      before do
        diff_for_path(from: source_ref, to: target_ref.succ, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST create' do
    subject(:create_request) { post :create, params: request_params }

    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        from: source_ref,
        to: target_ref
      }
    end

    context 'when sending valid params' do
      let(:source_ref) { "improve%2Fawesome" }
      let(:target_ref) { "feature" }

      it 'redirects back to show' do
        create_request

        expect(response).to redirect_to(project_compare_path(project, to: target_ref, from: source_ref))
      end
    end

    context 'when sending invalid params' do
      context 'when the source ref is empty and target ref is set' do
        let(:source_ref) { '' }
        let(:target_ref) { 'master' }

        it 'redirects back to index and preserves the target ref' do
          create_request

          expect(response).to redirect_to(project_compare_index_path(project, to: target_ref))
        end
      end

      context 'when the target ref is empty and source ref is set' do
        let(:source_ref) { 'master' }
        let(:target_ref) { '' }

        it 'redirects back to index and preserves source ref' do
          create_request

          expect(response).to redirect_to(project_compare_index_path(project, from: source_ref))
        end
      end

      context 'when the target and source ref are empty' do
        let(:source_ref) { '' }
        let(:target_ref) { '' }

        it 'redirects back to index' do
          create_request

          expect(response).to redirect_to(namespace_project_compare_index_path)
        end
      end
    end
  end

  describe 'GET signatures' do
    subject(:signatures_request) { get :signatures, params: request_params }

    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        from: source_ref,
        to: target_ref,
        format: :json
      }
    end

    context 'when the source and target refs exist' do
      let(:source_ref) { "improve%2Fawesome" }
      let(:target_ref) { "feature" }

      context 'when the user has access to the project' do
        render_views

        let(:signature_commit) { build(:commit, project: project, safe_message: "message", sha: 'signature_commit') }
        let(:non_signature_commit) { build(:commit, project: project, safe_message: "message", sha: 'non_signature_commit') }

        before do
          escaped_source_ref = Addressable::URI.unescape(source_ref)
          escaped_target_ref = Addressable::URI.unescape(target_ref)

          compare_service = CompareService.new(project, escaped_target_ref)
          compare = compare_service.execute(project, escaped_source_ref)

          expect(CompareService).to receive(:new).with(project, escaped_target_ref).and_return(compare_service)
          expect(compare_service).to receive(:execute).with(project, escaped_source_ref).and_return(compare)

          expect(compare).to receive(:commits).and_return([signature_commit, non_signature_commit])
          expect(non_signature_commit).to receive(:has_signature?).and_return(false)
        end

        it 'returns only the commit with a signature' do
          signatures_request

          expect(response).to have_gitlab_http_status(200)
          parsed_body = JSON.parse(response.body)
          signatures = parsed_body['signatures']

          expect(signatures.size).to eq(1)
          expect(signatures.first['commit_sha']).to eq(signature_commit.sha)
          expect(signatures.first['html']).to be_present
        end
      end

      context 'when the user does not have access to the project' do
        before do
          project.team.truncate
        end

        it 'returns a 404' do
          signatures_request

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when the source ref does not exist' do
      let(:source_ref) { 'non-existent-ref-source' }
      let(:target_ref) { "feature" }

      it 'returns no signatures' do
        signatures_request

        expect(response).to have_gitlab_http_status(200)
        parsed_body = JSON.parse(response.body)
        expect(parsed_body['signatures']).to be_empty
      end
    end

    context 'when the target ref does not exist' do
      let(:target_ref) { 'non-existent-ref-target' }
      let(:source_ref) { "improve%2Fawesome" }

      it 'returns no signatures' do
        signatures_request

        expect(response).to have_gitlab_http_status(200)
        parsed_body = JSON.parse(response.body)
        expect(parsed_body['signatures']).to be_empty
      end
    end
  end
end
