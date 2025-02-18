# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CompareController, feature_category: :source_code_management do
  include ProjectForksHelper

  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  let(:private_fork) { fork_project(project, nil, repository: true).tap { |fork| fork.update!(visibility: 'private') } }
  let(:public_fork) do
    fork_project(project, nil, repository: true).tap do |fork|
      fork.update!(visibility: 'public')
      # Create a reference that only exists in this project
      fork.repository.create_ref('refs/heads/improve/awesome', 'refs/heads/improve/more-awesome')
    end
  end

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET index' do
    let(:params) { { namespace_id: project.namespace, project_id: project } }

    render_views

    before do
      get :index, params: params
    end

    it 'returns successfully' do
      expect(response).to be_successful
    end

    context 'with incorrect parameters' do
      let(:params) { super().merge(from: { invalid: :param }, to: { also: :invalid }) }

      it 'returns successfully' do
        expect(response).to be_successful
      end
    end

    context 'with missing parameters' do
      let(:params) { super().merge(from: '', to: '') }

      it 'returns successfully' do
        expect(response).to be_successful
      end
    end
  end

  describe 'GET show' do
    render_views

    subject(:show_request) { get :show, params: request_params }

    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        from_project_id: from_project_id,
        from: from_ref,
        to: to_ref,
        w: whitespace,
        page: page,
        straight: straight
      }
    end

    let(:whitespace) { nil }
    let(:straight) { nil }
    let(:page) { nil }

    context 'when the refs exist in the same project' do
      context 'when we set the white space param' do
        let(:from_project_id) { nil }
        let(:from_ref) { '08f22f25' }
        let(:to_ref) { '66eceea0' }
        let(:whitespace) { 1 }

        it 'shows some diffs with ignore whitespace change option' do
          show_request

          expect(response).to be_successful
          diff_file = assigns(:diffs).diff_files.first
          expect(diff_file).not_to be_nil
          expect(assigns(:commits).length).to be >= 1
          # without whitespace option, there are more than 2 diff_splits
          diff_splits = diff_file.diff.diff.split("\n")
          expect(diff_splits.length).to be <= 2
        end
      end

      context 'when we do not set the white space param' do
        let(:from_project_id) { nil }
        let(:from_ref) { 'improve%2Fawesome' }
        let(:to_ref) { 'feature' }
        let(:whitespace) { nil }

        it 'sets the diffs and commits ivars' do
          show_request

          expect(response).to be_successful
          expect(assigns(:diffs).diff_files.first).not_to be_nil
          expect(assigns(:commits).length).to be >= 1
        end
      end
    end

    context 'when refs have CI::Pipeline' do
      let(:from_project_id) { nil }
      let(:from_ref) { '08f22f25' }
      let(:to_ref) { '59e29889' }

      before do
        create(:ci_pipeline, project: project)
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { show_request }

        # Only 1 query to ci/pipeline.rb is allowed
        expect(control.find_query(/pipeline\.rb/, 1)).to be_empty
      end
    end

    context 'when the refs exist in different projects that the user can see' do
      let(:from_project_id) { public_fork.id }
      let(:from_ref) { 'improve%2Fmore-awesome' }
      let(:to_ref) { 'feature' }
      let(:whitespace) { nil }

      it 'shows the diff' do
        show_request

        expect(response).to be_successful
        expect(assigns(:diffs).diff_files.first).not_to be_nil
        expect(assigns(:commits).length).to be >= 1
      end
    end

    context 'when comparing missing commits between source and target' do
      let(:from_project_id) { nil }
      let(:from_ref) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
      let(:to_ref) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
      let(:page) { 1 }

      context 'when comparing them in the other direction' do
        let(:straight) { "false" }
        let(:from_ref) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
        let(:to_ref) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }

        it 'the commits are there' do
          show_request

          expect(response).to be_successful
          expect(assigns(:commits).length).to be >= 2
          expect(assigns(:diffs).raw_diff_files.size).to be >= 2
          expect(assigns(:diffs).diff_files.first).to be_present
        end
      end

      context 'with straight mode true' do
        let(:from_ref) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
        let(:to_ref) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }

        let(:straight) { "true" }

        it 'the commits are empty, but the removed lines are visible as diffs' do
          show_request

          expect(response).to be_successful
          expect(assigns(:commits).length).to eq 0
          expect(assigns(:diffs).diff_files.size).to be >= 4
        end
      end

      context 'with straight mode false' do
        let(:from_ref) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
        let(:to_ref) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }

        let(:straight) { "false" }

        it 'the additional commits are not visible in diffs and commits' do
          show_request

          expect(response).to be_successful
          expect(assigns(:commits).length).to eq 0
          expect(assigns(:diffs).diff_files.size).to eq 0
        end
      end
    end

    context 'when the refs exist in different projects but the user cannot see' do
      let(:from_project_id) { private_fork.id }
      let(:from_ref) { 'improve%2Fmore-awesome' }
      let(:to_ref) { 'feature' }
      let(:whitespace) { nil }

      it 'does not show the diff' do
        show_request

        expect(response).to be_successful
        expect(assigns(:diffs)).to be_empty
        expect(assigns(:commits)).to be_empty
      end
    end

    context 'when the target project is the default source but hidden to the user' do
      let(:project) { create(:project, :repository, :private) }
      let(:from_ref) { 'improve%2Fmore-awesome' }
      let(:to_ref) { 'feature' }
      let(:whitespace) { nil }

      let(:request_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          from: from_ref,
          to: to_ref,
          w: whitespace,
          page: page,
          straight: straight
        }
      end

      it 'does not show the diff' do
        allow(controller).to receive(:source_project).and_return(project)
        expect(project).to receive(:default_merge_request_target).and_return(private_fork)

        show_request

        expect(response).to be_successful
        expect(assigns(:diffs)).to be_empty
        expect(assigns(:commits)).to be_empty
      end
    end

    context 'when the source ref does not exist' do
      let(:from_project_id) { nil }
      let(:from_ref) { 'non-existent-source-ref' }
      let(:to_ref) { 'feature' }

      it 'sets empty diff and commit ivars' do
        show_request

        expect(response).to be_successful
        expect(assigns(:diffs)).to eq([])
        expect(assigns(:commits)).to eq([])
      end
    end

    context 'when the target ref does not exist' do
      let(:from_project_id) { nil }
      let(:from_ref) { 'improve%2Fawesome' }
      let(:to_ref) { 'non-existent-target-ref' }

      it 'sets empty diff and commit ivars' do
        show_request

        expect(response).to be_successful
        expect(assigns(:diffs)).to eq([])
        expect(assigns(:commits)).to eq([])
      end
    end

    context 'when format is not supported' do
      let(:from_project_id) { nil }
      let(:request_params) { super().merge(format: 'json') }
      let(:from_ref) { 'master' }
      let(:to_ref) { 'feature' }

      it 'returns a 404 error' do
        show_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the target ref is invalid' do
      let(:from_project_id) { nil }
      let(:from_ref) { 'improve%2Fawesome' }
      let(:to_ref) { "master%' AND 2554=4423 AND '%'='" }

      it 'shows a flash message and redirects' do
        show_request

        expect(flash[:alert]).to eq("Invalid branch name(s): master%' AND 2554=4423 AND '%'='")
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when the from_ref and to_ref are the same' do
      let(:from_project_id) { nil }
      let(:from_ref) { 'master' }
      let(:to_ref) { "master" }

      it 'shows a message that refs are identical' do
        show_request

        expect(response).to be_successful
        expect(response.body).to include('are the same')
      end
    end

    context 'when the source ref is invalid' do
      let(:from_project_id) { nil }
      let(:from_ref) { "master%' AND 2554=4423 AND '%'='" }
      let(:to_ref) { 'improve%2Fawesome' }

      it 'shows a flash message and redirects' do
        show_request

        expect(flash[:alert]).to eq("Invalid branch name(s): master%' AND 2554=4423 AND '%'='")
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when the both refs are invalid' do
      let(:from_project_id) { nil }
      let(:from_ref) { "master%' AND 2554=4423 AND '%'='" }
      let(:to_ref) { "improve%' =,awesome" }

      it 'shows a flash message and redirects' do
        show_request

        expect(flash[:alert]).to eq("Invalid branch name(s): improve%' =,awesome, master%' AND 2554=4423 AND '%'='")
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when page is valid' do
      let(:from_project_id) { nil }
      let(:from_ref) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
      let(:to_ref) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
      let(:page) { 1 }

      shared_examples 'valid compare page' do
        it 'shows the diff' do
          show_request

          expect(response).to be_successful
          expect(assigns(:diffs).diff_files.first).to be_present
          expect(assigns(:commits).length).to be >= 1
        end
      end

      it_behaves_like 'valid compare page'

      it 'only loads blobs in the current page' do
        stub_const('Projects::CompareController::COMMIT_DIFFS_PER_PAGE', 1)

        expect_next_instance_of(Repository) do |repository|
          # This comparison contains 4 changed files but we expect only the blobs for the first one to be loaded
          expect(repository).to receive(:blobs_at).with(
            contain_exactly([from_ref, '.gitmodules'], [to_ref, '.gitmodules']), anything
          ).and_call_original
        end

        show_request

        expect(response).to be_successful
      end

      context 'when from_ref is HEAD ref' do
        let(:from_ref) { 'HEAD' }
        let(:to_ref) { 'feature' } # Need to change to_ref too so there's something to compare with HEAD

        it_behaves_like 'valid compare page'
      end

      context 'when to_ref is HEAD ref' do
        let(:to_ref) { 'HEAD' }

        it_behaves_like 'valid compare page'
      end
    end

    context 'when page is not valid' do
      let(:from_project_id) { nil }
      let(:from_ref) { '08f22f25' }
      let(:to_ref) { '66eceea0' }
      let(:page) { ['invalid'] }

      it 'does not return an error' do
        show_request

        expect(response).to be_successful
      end
    end
  end

  describe 'GET diff_for_path' do
    subject(:diff_for_path_request) { get :diff_for_path, params: request_params }

    let(:request_params) do
      {
        from_project_id: from_project_id,
        from: from_ref,
        to: to_ref,
        namespace_id: project.namespace,
        project_id: project,
        old_path: old_path,
        new_path: new_path
      }
    end

    let(:existing_path) { 'files/ruby/feature.rb' }

    let(:from_project_id) { nil }
    let(:from_ref) { 'improve%2Fawesome' }
    let(:to_ref) { 'feature' }
    let(:old_path) { existing_path }
    let(:new_path) { existing_path }

    context 'when the source and target refs exist in the same project' do
      context 'when the user has access target the project' do
        context 'when the path exists in the diff' do
          it 'disables diff notes' do
            diff_for_path_request

            expect(assigns(:diff_notes_disabled)).to be_truthy
          end

          it 'only renders the diffs for the path given' do
            expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
              expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
              meth.call(diffs)
            end

            diff_for_path_request
          end
        end

        context 'when the path does not exist in the diff' do
          let(:old_path) { existing_path.succ }
          let(:new_path) { existing_path.succ }

          it 'returns a 404' do
            diff_for_path_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when the user does not have access target the project' do
        before do
          project.team.truncate
        end

        it 'returns a 404' do
          diff_for_path_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the source and target refs exist in different projects and the user can see' do
      let(:from_project_id) { public_fork.id }
      let(:from_ref) { 'improve%2Fmore-awesome' }

      it 'shows the diff for that path' do
        expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
          expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
          meth.call(diffs)
        end

        diff_for_path_request
      end
    end

    context 'when the source and target refs exist in different projects and the user cannot see' do
      let(:from_project_id) { private_fork.id }

      it 'does not show the diff for that path' do
        diff_for_path_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the source ref does not exist' do
      let(:from_ref) { 'this-ref-does-not-exist' }

      it 'returns a 404' do
        diff_for_path_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the target ref does not exist' do
      let(:to_ref) { 'this-ref-does-not-exist' }

      it 'returns a 404' do
        diff_for_path_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST create' do
    subject(:create_request) { post :create, params: request_params }

    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        from_project_id: from_project_id,
        from: from_ref,
        to: to_ref,
        straight: straight,
        to_project_id: to_project_id
      }
    end

    let(:straight) { false }
    let(:to_project_id) { nil }
    let(:from_project_id) { nil }

    context 'when sending valid params' do
      let(:from_ref) { 'awesome%2Ffeature' }
      let(:to_ref) { 'feature' }

      context 'without a from_project_id' do
        let(:from_project_id) { nil }

        it 'redirects to the show page' do
          create_request

          expect(response).to redirect_to(project_compare_path(project, from: from_ref, to: to_ref))
        end
      end

      context 'with a from_project_id' do
        let(:from_project_id) { 'something or another' }

        it 'redirects to the show page without interpreting from_project_id' do
          create_request

          expect(response).to redirect_to(project_compare_path(project, from: from_ref, to: to_ref, from_project_id: from_project_id))
        end
      end

      context 'when straight is true' do
        let(:straight) { true }

        it 'redirects to project_compare_with_two_dots_path' do
          create_request

          expect(response).to redirect_to(project_compare_with_two_dots_path(project, from: from_ref, to: to_ref, from_project_id: from_project_id))
        end

        context 'when the source and target are the same project' do
          let(:from_project_id) { 'the_same_project_id' }
          let(:to_project_id) { 'the_same_project_id' }

          it 'includes from_project_id in the params' do
            create_request

            expect(response).to redirect_to(project_compare_with_two_dots_path(project, from: from_ref, to: to_ref, from_project_id: from_project_id))
          end
        end

        context 'when the source and target are not the same project' do
          let(:from_project_id) { 'from_project_id' }
          let(:to_project_id) { 'to_project_id' }

          it 'includes from_project_id in the params' do
            create_request

            expect(response).to redirect_to(project_compare_with_two_dots_path(project, from: from_ref, to: to_ref, from_project_id: from_project_id))
          end
        end
      end

      context 'when straight is false' do
        let(:straight) { false }

        it 'redirects to project_compare_path' do
          create_request

          expect(response).to redirect_to(project_compare_path(project, from: from_ref, to: to_ref, from_project_id: from_project_id))
        end
      end
    end

    context 'when sending invalid params' do
      where(:from_ref, :to_ref, :from_project_id, :expected_redirect_params) do
        ''     | ''     | ''    | {}
        'main' | ''     | ''    | { from: 'main' }
        ''     | 'main' | ''    | { to: 'main' }
        ''     | ''     | '1'   | { from_project_id: 1 }
        'main' | ''     | '1'   | { from: 'main', from_project_id: 1 }
        ''     | 'main' | '1'   | { to: 'main', from_project_id: 1 }
        ['a']  | ['b']  | ['c'] | {}
      end

      with_them do
        let(:expected_redirect) { project_compare_index_path(project, expected_redirect_params) }

        it 'redirects back to the index' do
          create_request

          expect(response).to redirect_to(expected_redirect)
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
        from: from_ref,
        to: to_ref,
        straight: straight,
        format: :json
      }
    end

    let(:straight) { nil }

    context 'when the source and target refs exist' do
      let(:from_ref) { 'improve%2Fawesome' }
      let(:to_ref) { 'feature' }

      context 'when the user has access to the project' do
        render_views

        let(:signature_commit) { project.commit_by(oid: '0b4bc9a49b562e85de7cc9e834518ea6828729b9') }
        let(:non_signature_commit) { build(:commit, project: project, safe_message: "message", sha: 'non_signature_commit') }

        before do
          escaped_from_ref = Addressable::URI.unescape(from_ref)
          escaped_to_ref = Addressable::URI.unescape(to_ref)

          compare_service = CompareService.new(project, escaped_to_ref)
          compare = compare_service.execute(project, escaped_from_ref, straight: false)

          expect(CompareService).to receive(:new).with(project, escaped_to_ref).and_return(compare_service)
          expect(compare_service).to receive(:execute).with(project, escaped_from_ref, straight: false).and_return(compare)

          expect(compare).to receive(:commits).and_return(CommitCollection.new(project, [signature_commit, non_signature_commit]))
          expect(non_signature_commit).to receive(:has_signature?).and_return(false)
        end

        it 'returns only the commit with a signature' do
          signatures_request

          expect(response).to have_gitlab_http_status(:ok)
          signatures = json_response['signatures']

          expect(signatures.size).to eq(1)
          expect(signatures.first['commit_sha']).to eq(signature_commit.sha)
          expect(signatures.first['html']).to be_present
        end
      end

      context 'when the user has access to the project with straight compare' do
        render_views

        let(:signature_commit) { project.commit_by(oid: '0b4bc9a49b562e85de7cc9e834518ea6828729b9') }
        let(:non_signature_commit) { build(:commit, project: project, safe_message: "message", sha: 'non_signature_commit') }
        let(:straight) { "true" }

        before do
          escaped_from_ref = Addressable::URI.unescape(from_ref)
          escaped_to_ref = Addressable::URI.unescape(to_ref)

          compare_service = CompareService.new(project, escaped_to_ref)
          compare = compare_service.execute(project, escaped_from_ref)

          expect(CompareService).to receive(:new).with(project, escaped_to_ref).and_return(compare_service)
          expect(compare_service).to receive(:execute).with(project, escaped_from_ref, straight: true).and_return(compare)

          expect(compare).to receive(:commits).and_return(CommitCollection.new(project, [signature_commit, non_signature_commit]))
          expect(non_signature_commit).to receive(:has_signature?).and_return(false)
        end

        it 'returns only the commit with a signature' do
          signatures_request

          expect(response).to have_gitlab_http_status(:ok)
          signatures = json_response['signatures']

          expect(signatures.size).to eq(1)
          expect(signatures.first['commit_sha']).to eq(signature_commit.sha)
          expect(signatures.first['html']).to be_present
        end
      end

      context 'when the user does not have access to the project', :sidekiq_inline do
        before do
          project.team.truncate
          project.update!(visibility: 'private')
        end

        it 'returns a 404' do
          signatures_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the source ref does not exist' do
      let(:from_ref) { 'non-existent-ref-source' }
      let(:to_ref) { 'feature' }

      it 'returns no signatures' do
        signatures_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['signatures']).to be_empty
      end
    end

    context 'when the target ref does not exist' do
      let(:from_ref) { 'improve%2Fawesome' }
      let(:to_ref) { 'non-existent-ref-target' }

      it 'returns no signatures' do
        signatures_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['signatures']).to be_empty
      end
    end
  end

  describe 'GET #rapid_diffs' do
    subject(:send_request) { get :rapid_diffs, params: request_params }

    let(:format) { :html }
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        from: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
        to: '5937ac0a7beb003549fc5fd26fc247adbce4a52e'
      }
    end

    it 'renders rapid_diffs template' do
      send_request

      expect(assigns(:diffs).diff_files.first).to be_present
      expect(response).to render_template(:rapid_diffs)
    end

    context 'when the feature flag rapid_diffs is disabled' do
      before do
        stub_feature_flags(rapid_diffs: false)
      end

      it 'returns 404' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
