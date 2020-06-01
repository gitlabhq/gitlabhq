# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Cache
      class Map
        def initialize(project)
          @project = project
        end

        def get_gitlab_model(phabricator_id)
          cached_info = get(phabricator_id)

          if cached_info[:classname] && cached_info[:database_id]
            object = cached_info[:classname].constantize.find_by_id(cached_info[:database_id])
          else
            object = yield if block_given?
            set_gitlab_model(object, phabricator_id) if object
          end

          object
        end

        def set_gitlab_model(object, phabricator_id)
          set(object.class, object.id, phabricator_id)
        end

        private

        attr_reader :project

        def set(klass_name, object_id, phabricator_id)
          key = cache_key_for_phabricator_id(phabricator_id)

          redis.with do |r|
            r.multi do |multi|
              multi.mapped_hmset(key,
                             { classname: klass_name, database_id: object_id })
              multi.expire(key, timeout)
            end
          end
        end

        def get(phabricator_id)
          key = cache_key_for_phabricator_id(phabricator_id)

          redis.with do |r|
            r.pipelined do |pipe|
              # Extend the TTL when a key was
              pipe.expire(key, timeout)
              pipe.mapped_hmget(key, :classname, :database_id)
            end.last
          end
        end

        def cache_key_for_phabricator_id(phabricator_id)
          "#{Redis::Cache::CACHE_NAMESPACE}/phabricator-import/#{project.id}/#{phabricator_id}"
        end

        def redis
          Gitlab::Redis::Cache
        end

        def timeout
          # Setting the timeout to the same one as we do for clearing stuck jobs
          # this makes sure all cache is available while the import is running.
          Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION
        end
      end
    end
  end
end
