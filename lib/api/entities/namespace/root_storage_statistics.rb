# frozen_string_literal: true

module API
  module Entities
    class Namespace
      class RootStorageStatistics < Grape::Entity
        expose  :build_artifacts_size, documentation: { type: 'integer', desc: 'CI artifacts size in bytes.' }
        expose  :container_registry_size, documentation: { type: 'integer', desc: 'Container Registry size in bytes.' }
        expose  :registry_size_estimated,
          as: :container_registry_size_is_estimated,
          documentation: { type: 'boolean',
                           desc: 'Indicates whether the deduplicated Container Registry size for ' \
                             'the namespace is an estimated value or not.' }
        expose  :dependency_proxy_size, documentation: { type: 'integer', desc: 'Dependency Proxy sizes in bytes.' }
        expose  :lfs_objects_size, documentation: { type: 'integer', desc: 'LFS objects size in bytes.' }
        expose  :packages_size, documentation: { type: 'integer', desc: 'Packages size in bytes.' }
        expose  :pipeline_artifacts_size,
          documentation: { type: 'integer', desc: 'CI pipeline artifacts size in bytes.' }
        expose  :repository_size, documentation: { type: 'integer', desc: 'Git repository size in bytes.' }
        expose  :snippets_size, documentation: { type: 'integer', desc: 'Snippets size in bytes.' }
        expose  :storage_size, documentation: { type: 'integer', desc: 'Total storage in bytes.' }
        expose  :uploads_size, documentation: { type: 'integer', desc: 'Uploads size in bytes.' }
        expose  :wiki_size, documentation: { type: 'integer', desc: 'Wiki size in bytes.' }
      end
    end
  end
end
