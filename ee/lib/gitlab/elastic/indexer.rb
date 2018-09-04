# Create a separate process, which does not load the Rails environment, to index
# each repository. This prevents memory leaks in the indexer from affecting the
# rest of the application.
module Gitlab
  module Elastic
    class Indexer
      EXPERIMENTAL_INDEXER = 'gitlab-elasticsearch-indexer'.freeze

      Error = Class.new(StandardError)

      def self.experimental_indexer_present?
        Gitlab::Utils.which(EXPERIMENTAL_INDEXER).present?
      end

      attr_reader :project

      def initialize(project)
        @project = project

        # We accept any form of settings, including string and array
        # This is why JSON is needed
        @vars = {
          'ELASTIC_CONNECTION_INFO' => Gitlab::CurrentSettings.elasticsearch_config.to_json,
          'RAILS_ENV'               => Rails.env
        }
      end

      def run(from_sha = nil, to_sha = nil)
        to_sha = nil if to_sha == Gitlab::Git::BLANK_SHA

        head_commit = repository.try(:commit)

        if repository.nil? || !repository.exists? || repository.empty? || head_commit.nil?
          update_index_status(Gitlab::Git::BLANK_SHA)
          return
        end

        run_indexer!(from_sha, to_sha)
        update_index_status(to_sha)

        true
      end

      private

      def repository
        project.repository
      end

      def path_to_indexer
        if Gitlab::CurrentSettings.elasticsearch_experimental_indexer? && self.class.experimental_indexer_present?
          EXPERIMENTAL_INDEXER
        else
          Rails.root.join('bin', 'elastic_repo_indexer').to_s
        end
      end

      def run_indexer!(from_sha, to_sha)
        command = ::Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          [path_to_indexer, project.id.to_s, repository.path_to_repo]
        end
        vars = @vars.merge('FROM_SHA' => from_sha, 'TO_SHA' => to_sha)

        output, status = Gitlab::Popen.popen(command, nil, vars)

        raise Error, output unless status&.zero?
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_index_status(to_sha)
        head_commit = repository.try(:commit)

        # Use the eager-loaded association if available. An index_status should
        # always be created, even if the repository is empty, so we know it's
        # been looked at.
        index_status = project.index_status
        index_status ||=
          begin
            IndexStatus.find_or_create_by(project_id: project.id)
          rescue ActiveRecord::RecordNotUnique
            retry
          end

        # Don't update the index status if we never reached HEAD
        return if head_commit && to_sha && head_commit.sha != to_sha

        sha = head_commit.try(:sha)
        sha ||= Gitlab::Git::BLANK_SHA
        index_status.update(last_commit: sha, indexed_at: Time.now)
        project.index_status(true)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
