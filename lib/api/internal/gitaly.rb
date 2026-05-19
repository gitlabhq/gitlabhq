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

        def members_for_pool(pool)
          members = []

          members << member_hash(pool.source_project, is_upstream: true) if pool.source_project

          unless params[:upstream_only]
            pool.member_projects.id_not_in(Array(pool.source_project_id).compact).find_each do |project|
              members << member_hash(project, is_upstream: false)
            end
          end

          members
        end
      end

      namespace 'internal' do
        namespace 'gitaly' do
          params do
            requires :disk_paths, type: Array[String], limit: 500,
              desc: 'The on-disk paths of the pool repositories. Limited to 500'
            requires :storage, type: String, desc: 'The storage shard name'
            optional :upstream_only, type: Boolean, default: false, desc: 'Return only the upstream repository'
          end
          desc 'List Gitaly object pool members'
          route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
          get '/object_pool_members', feature_category: :gitaly, urgency: :low do
            pools = PoolRepository.by_disk_path_and_shard_name(params[:disk_paths], params[:storage])
                      .index_by(&:disk_path)

            # Iterate over the pools using the disk_paths provided in the request.
            result = params[:disk_paths].each_with_object({}) do |disk_path, hash|
              pool = pools[disk_path]
              members = pool.nil? ? [] : members_for_pool(pool)

              hash[disk_path] = Entities::PoolRepositoryMember.represent(members).map(&:as_json)
            end

            present result
          end
        end
      end
    end
  end
end
