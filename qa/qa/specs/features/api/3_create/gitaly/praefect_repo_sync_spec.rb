# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Praefect repository commands', :orchestrated, :gitaly_cluster do
      let(:praefect_manager) { Service::PraefectManager.new }

      let(:repo1) { { "relative_path" => "@hashed/repo1.git", "storage" => "gitaly1", "virtual_storage" => "default" } }
      let(:repo2) { { "relative_path" => "@hashed/path/to/repo2.git", "storage" => "gitaly3", "virtual_storage" => "default" } }

      before do
        praefect_manager.add_repo_to_disk(praefect_manager.primary_node, repo1["relative_path"])
        praefect_manager.add_repo_to_disk(praefect_manager.tertiary_node, repo2["relative_path"])
      end

      after do
        praefect_manager.remove_repo_from_disk(repo1["relative_path"])
        praefect_manager.remove_repo_from_disk(repo2["relative_path"])
        praefect_manager.remove_repository_from_praefect_database(repo1["relative_path"])
        praefect_manager.remove_repository_from_praefect_database(repo2["relative_path"])
      end

      it 'allows admin to manage difference between praefect database and disk state', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2344' do
        # Some repos are on disk that praefect is not aware of
        untracked_repositories = praefect_manager.list_untracked_repositories
        expect(untracked_repositories).to include(repo1)
        expect(untracked_repositories).to include(repo2)

        # admin manually adds the first repo to the praefect database
        praefect_manager.track_repository_in_praefect(repo1["relative_path"], repo1["storage"], repo1["virtual_storage"])
        untracked_repositories = praefect_manager.list_untracked_repositories
        expect(untracked_repositories).not_to include(repo1)
        expect(untracked_repositories).to include(repo2)
        expect(praefect_manager.repository_exists_on_node_disk?(praefect_manager.primary_node, repo1["relative_path"])).to be true
        expect(praefect_manager.praefect_database_tracks_repo?(repo1["relative_path"])).to be true

        # admin manually adds the second repo to the praefect database
        praefect_manager.track_repository_in_praefect(repo2["relative_path"], repo2["storage"], repo2["virtual_storage"])
        untracked_repositories = praefect_manager.list_untracked_repositories
        expect(untracked_repositories).not_to include(repo2)
        expect(praefect_manager.repository_exists_on_node_disk?(praefect_manager.tertiary_node, repo2["relative_path"])).to be true
        expect(praefect_manager.praefect_database_tracks_repo?(repo2["relative_path"])).to be true

        # admin ensures replication to other nodes occurs
        expect(praefect_manager.repository_replicated_to_disk?(praefect_manager.secondary_node, repo1["relative_path"])).to be true
        expect(praefect_manager.repository_replicated_to_disk?(praefect_manager.tertiary_node, repo1["relative_path"])).to be true
        expect(praefect_manager.repository_replicated_to_disk?(praefect_manager.primary_node, repo2["relative_path"])).to be true
        expect(praefect_manager.repository_replicated_to_disk?(praefect_manager.secondary_node, repo2["relative_path"])).to be true

        # admin chooses to remove the first repo completely from praefect and disk
        praefect_manager.remove_tracked_praefect_repository(repo1["relative_path"], repo1["virtual_storage"])
        expect(praefect_manager.repository_exists_on_node_disk?(praefect_manager.primary_node, repo1["relative_path"])).to be false
        expect(praefect_manager.repository_exists_on_node_disk?(praefect_manager.secondary_node, repo1["relative_path"])).to be false
        expect(praefect_manager.repository_exists_on_node_disk?(praefect_manager.tertiary_node, repo1["relative_path"])).to be false
        expect(praefect_manager.praefect_database_tracks_repo?(repo1["relative_path"])).to be false

        untracked_repositories = praefect_manager.list_untracked_repositories
        expect(untracked_repositories).not_to include(repo1)
      end
    end
  end
end
