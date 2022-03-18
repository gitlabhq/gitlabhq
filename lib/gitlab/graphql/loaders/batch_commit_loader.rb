# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchCommitLoader
        def initialize(container_class:, container_id:, oid:)
          @container_class = container_class
          @container_id = container_id
          @oid = oid
        end

        def find
          Gitlab::Graphql::Lazy.with_value(find_containers) do |container|
            BatchLoader::GraphQL.for(oid).batch(key: container) do |oids, loader, args|
              container = args[:key]

              container.repository.commits_by(oids: oids).each do |commit|
                loader.call(commit.id, commit) if commit
              end
            end
          end
        end

        private

        def find_containers
          BatchLoader::GraphQL.for(container_id.to_i).batch(key: container_class) do |ids, loader, args|
            model = args[:key]
            results = model.includes(:route).id_in(ids) # rubocop: disable CodeReuse/ActiveRecord

            results.each { |record| loader.call(record.id, record) }
          end
        end

        attr_reader :container_class, :container_id, :oid
      end
    end
  end
end
