module Gitlab
  # Similar to UrlBuilder, but using IDs to avoid querying the DB for objects
  # Useful for using in conjunction with Arel queries.
  class LightUrlBuilder
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper
    include ActionView::RecordIdentifier

    def self.build(*args)
      new(*args).url
    end

    def initialize(entity:, project: nil, id:, opts: {})
      @entity = entity
      @project = project
      @id = id
      @opts = opts
    end

    def url
      url_method = "#{@entity}_url"
      raise NotImplementedError.new("No Light URL builder defined for #{@entity.to_s}") unless respond_to?(url_method)

      public_send(url_method)
    end

    def issue_url
      namespace_project_issue_url({
                                    namespace_id: @project.namespace,
                                    project_id: @project,
                                    id: @id
                                  }.merge!(@opts))
    end

    def user_avatar_url
      User.find(@id).avatar_url
    end

    def commit_url
      namespace_project_commit_url({
                                     namespace_id: @project.namespace,
                                     project_id: @project,
                                     id: @id
                                   }.merge!(@opts))
    end

    def merge_request_url
      namespace_project_merge_request_url({
                                            namespace_id: @project.namespace,
                                            project_id: @project,
                                            id: @id
                                          }.merge!(@opts))
    end

    def branch_url
      "#{project_url(@project)}/commits/#{@id}"
    end

    def user_url
      Gitlab::Routing.url_helpers.user_url(@id)
    end

    def build_url
      namespace_project_build_url(@project.namespace, @project, @id)
    end
  end
end
