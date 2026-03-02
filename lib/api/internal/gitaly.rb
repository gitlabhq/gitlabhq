# frozen_string_literal: true

module API
  module Internal
    class Gitaly < ::API::Base
      before do
        authenticate_by_gitlab_shell_token!
      end

      helpers do
        def member_hash(project, is_upstream:)
          {
            relative_path: "#{project.disk_path}.git",
            public: project.public?,
            is_upstream: is_upstream
          }
        end
      end

      namespace 'internal' do
        namespace 'gitaly' do
          params do
            requires :disk_path, type: String, desc: 'The on-disk path of the pool repository'
            requires :storage, type: String, desc: 'The storage shard name'
            optional :upstream_only, type: Boolean, default: false, desc: 'Return only the upstream repository'
          end
          get '/object_pool_members', feature_category: :gitaly, urgency: :low do
            pool = PoolRepository.by_disk_path_and_shard_name(params[:disk_path], params[:storage]).first
            not_found! if pool.nil?

            members = []

            members << member_hash(pool.source_project, is_upstream: true) if pool.source_project

            unless params[:upstream_only]
              scope = pool.member_projects
              # The pool may not always have a source project, for example if it was later deleted.
              # It's still valid for a pool to exist without one.
              scope = scope.id_not_in(pool.source_project_id) if pool.source_project_id
              scope.find_each do |project|
                members << member_hash(project, is_upstream: false)
              end
            end

            present members, with: Entities::PoolRepositoryMember
          end
        end
      end
    end
  end
end
