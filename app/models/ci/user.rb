# User object is stored in session
module Ci
  class User
    DEVELOPER_ACCESS = 30

    attr_reader :attributes

    def initialize(hash)
      @attributes = hash
    end

    def gitlab_projects(search = nil, page = 1, per_page = 100)
      Rails.cache.fetch(cache_key(page, per_page, search)) do
        Ci::Project.from_gitlab(self, :authorized, { page: page, per_page: per_page, search: search, ci_enabled_first: true })
      end
    end

    def method_missing(meth, *args, &block)
      if attributes.has_key?(meth.to_s)
        attributes[meth.to_s]
      else
        super
      end
    end

    def avatar_url
      attributes['avatar_url']
    end

    def cache_key(*args)
      "#{self.id}:#{args.join(":")}:#{sync_at.to_s}"
    end

    def sync_at
      @sync_at ||= Time.now
    end

    def reset_cache
      @sync_at = Time.now
    end

    def authorized_runners
      Ci::Runner.specific.includes(:runner_projects).
        where(Ci::RunnerProject.table_name => { project_id: authorized_projects } )
    end

    def authorized_projects
      Ci::Project.where(gitlab_id: current_user.authorized_projects.map(&:id))
    end

    def authenticate_options
      if attributes['access_token']
        { access_token: attributes['access_token'] }
      else
        { private_token: attributes['private_token'] }
      end
    end

    private

    def project_info(project_gitlab_id)
      Rails.cache.fetch(cache_key("project_info", project_gitlab_id, sync_at)) do
        Ci::Network.new.project(authenticate_options, project_gitlab_id)
      end
    end
  end
end
