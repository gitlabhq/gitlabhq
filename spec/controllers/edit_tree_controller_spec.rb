require 'spec_helper'

describe Projects::EditTreeController do
  include RepoHelpers
  include ProjectHelpers

  let(:project) { create(:project, :public) }
  let(:user)    { create(:user) }

  describe '#show' do
    it 'returns not found if user cannot fork project' do
      get(:show, project_id: project.to_param, id: existing_file_id)

      expect(response.status).to eq(404)
    end

    it 'returns success denied if user cannot fork project' do
      give_fork_permission(user, project)

      get(:show, project_id: project.to_param, id: existing_file_id)

      expect(response).to be_success
    end
  end

  describe '#update' do
    it 'returns not found if user cannot push to project' do
      edit_file

      expect(response.status).to eq(404)
    end

    def edit_file
      put(:update, edit_file_opts)
    end

    def edit_file_opts
      {
        project_id: project.to_param,
        id: existing_file_id,
        content: new_content,
        commit_message: new_commit_message
      }
    end

    describe 'edit and create merge request' do
      before do
        give_push_permission(user, project)
      end

      it 'suceeds from origin to itself' do
        make_new_mr

        expect(user.already_forked?(project)).to be_false
        expect_make_new_mr_suceeded
      end

      it 'succeeds from an existing fork to origin' do
        fork = create(:project, namespace: user.namespace,
                                forked_from_project: project)
        expect(user.already_forked?(project)).to be_true
        expect(fork.repository.has_branch?(valid_new_branch_name)).to be_false

        make_new_mr(on_my_fork: '1')

        expect(user.already_forked?(project)).to be_true
        expect_make_new_mr_suceeded(fork, project)
      end

      it 'succeeds from a new fork to origin' do
        expect(user.already_forked?(project)).to be_false

        puts '================================================================================'
        puts 'ruby version = ' + RUBY_VERSION
        puts 'gitlab_url = ' + Settings.gitlab.url
        puts 'response code port 3001 = ' + Net::HTTP.get_response(URI('http://localhost:3001/')).code
        puts 'response body port 3001 = ' + Net::HTTP.get_response(URI('http://localhost:3001/')).body
        puts '# ls tests'
        system( 'ls ' + Rails.root.join('tmp', 'tests').to_s)
        puts '# cat gitlab-shell config'
        system( 'cat ' + Rails.root.join('tmp', 'tests', 'gitlab-shell', 'config.yml').to_s)
        puts '================================================================================'

        make_new_mr(on_my_fork: '1')

        expect(user.already_forked?(project)).to be_true
        fork = user.fork_of(project)
        expect_make_new_mr_suceeded(fork, project)
      end

      it 'succeeds from an existing fork to itself' do
        fork = create(:project, namespace: user.namespace,
                                forked_from_project: project)
        expect(user.already_forked?(project)).to be_true
        expect(fork.repository.has_branch?(valid_new_branch_name)).to be_false

        make_new_mr(project_id: fork.to_param)

        expect(user.already_forked?(project)).to be_true
        expect_make_new_mr_suceeded(fork, fork)
      end

      it 'fails and stays on edit page if the branch name already exists' do
        make_new_mr(new_branch_name: existing_branch_name)

        expect(flash['alert']).not_to be_nil
        expect(response).to be_success
      end

      it 'fails and stays on edit page if the branch name is invalid' do
        make_new_mr(new_branch_name: invalid_branch_name)

        expect(flash['alert']).not_to be_nil
        expect(response).to be_success
      end

      def make_new_mr(extra_put_opts = {})
        put_opts = edit_file_opts
        put_opts.merge!(
          create_merge_request: '1',
          new_branch_name: valid_new_branch_name
        )
        put_opts.merge!(extra_put_opts)
        put(:update, put_opts)
      end

      def expect_make_new_mr_suceeded(source_project = nil, target_project = nil)
        source_project ||= project
        target_project ||= source_project
        expect(source_project.repository.
               has_branch?(valid_new_branch_name)).to be_true
        expect(response).to redirect_to(new_project_merge_request_path(
          source_project,
          merge_request: {
            source_branch:     valid_new_branch_name,
            target_project_id: target_project.id
          }
        ))
      end
    end
  end
end
