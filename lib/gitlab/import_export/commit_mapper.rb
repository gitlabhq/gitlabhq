module Gitlab
  module ImportExport
    class CommitMapper
      def initialize(commits:, members_map:, project_id:, relation_factory: Gitlab::ImportExport::RelationFactory, user_admin:)
        @commits = commits
        @members_map = members_map
        @project_id = project_id
        @relation_factory = relation_factory
        @user_admin = user_admin
      end

      def ids_map
        @ids_map ||= map_commits
      end

      def map_commits
        @id_map = Hash.new(-1)

        @commits.each do |commit_hash|
          @relation_factory.update_user_references(commit_hash, @members_map)

          commit_hash['project_id'] = @project_id
          @relation_factory.update_project_references(commit_hash, Ci::Commit)
          create_commit_statuses(commit_hash)
          create_commit(commit_hash)
        end
        @id_map
      end

      def create_commit(commit_hash)
        old_id = commit_hash.delete('id')
        commit = Ci::Commit.new(commit_hash)
        commit.save!
        @id_map[old_id] = commit.id
      end

      def create_commit_statuses(commit_hash)
        commit_hash['statuses'].map! do |status_hash|
          @relation_factory.create(relation_sym: :statuses,
                                                       relation_hash: status_hash.merge('project_id' => @project_id,
                                                                                        'commit_id' => nil),
                                                       members_mapper: @members_map,
                                                       commits_mapper: nil,
                                                       user_admin: @user_admin)
        end
      end
    end
  end
end
