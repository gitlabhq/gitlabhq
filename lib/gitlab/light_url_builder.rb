module Gitlab
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
      case @entity
        when :issue
          issue_url
        when :user
          user_url(@id)
        when :user_avatar_url
          user_avatar_url
        when :commit_url
          commit_url
        when :merge_request
          mr_url
        else
          raise NotImplementedError.new("No URL builder defined for #{object.class}")
      end
    end

    private

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

    def mr_url
      namespace_project_merge_request_url({
                                            namespace_id: @project.namespace,
                                            project_id: @project,
                                            id: @id
                                          }.merge!(@opts))
    end
  end
end
