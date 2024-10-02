# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Snippet repository storage', :requires_admin, :orchestrated, :repository_storage do
      let(:source_storage) { { type: :gitaly, name: 'default' } }
      let(:destination_storage) { { type: :gitaly, name: QA::Runtime::Env.additional_repository_storage } }

      let(:snippet) do
        create(:project_snippet,
          title: 'Snippet to move storage of',
          file_name: 'original_file',
          file_content: 'Original file content',
          api_client: Runtime::API::Client.as_admin)
      end

      praefect_manager = Service::PraefectManager.new

      before do
        praefect_manager.gitlab = 'gitlab'
      end

      it 'moves snippet repository from one Gitaly storage to another', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347645' do
        expect(snippet).to have_file('original_file')
        expect { snippet.change_repository_storage(destination_storage[:name]) }.not_to raise_error
        expect { praefect_manager.verify_storage_move(source_storage, destination_storage, repo_type: :snippet) }.not_to raise_error

        # verifies you can push commits to the moved snippet
        Resource::Repository::Push.fabricate! do |push|
          push.repository_http_uri = snippet.http_url_to_repo
          push.file_name = 'new_file'
          push.file_content = 'new file content'
          push.commit_message = 'Adding a new snippet file'
          push.new_branch = false
        end

        aggregate_failures do
          expect(snippet).to have_file('original_file')
          expect(snippet).to have_file('new_file')
        end
      end
    end
  end
end
