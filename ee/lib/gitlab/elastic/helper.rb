module Gitlab
  module Elastic
    class Helper
      # rubocop: disable CodeReuse/ActiveRecord
      def self.create_empty_index
        index_name = Project.index_name
        settings = {}
        mappings = {}

        [
          Project,
          Issue,
          MergeRequest,
          Snippet,
          Note,
          Milestone,
          ProjectWiki,
          Repository
        ].each do |klass|
          settings.deep_merge!(klass.settings.to_hash)
          mappings.merge!(klass.mappings.to_hash)
        end

        client = Project.__elasticsearch__.client

        if client.indices.exists? index: index_name
          client.indices.delete index: index_name
        end

        client.indices.create index: index_name,
                              body: {
                                settings: settings.to_hash,
                                mappings: mappings.to_hash
                              }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.delete_index
        Project.__elasticsearch__.delete_index!
      end

      def self.refresh_index
        Project.__elasticsearch__.refresh_index!
      end
    end
  end
end
