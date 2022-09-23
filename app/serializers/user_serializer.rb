# frozen_string_literal: true

class UserSerializer < BaseSerializer
  entity UserEntity

  def represent(resource, opts = {}, entity = nil)
    if params[:merge_request_iid]
      merge_request = opts[:project].merge_requests.find_by_iid!(params[:merge_request_iid])
      preload_max_member_access(merge_request.project, Array(resource))

      super(resource, opts.merge(merge_request: merge_request, suggested: params[:suggested]), MergeRequestUserEntity)
    else
      super
    end
  end

  private

  def preload_max_member_access(project, users)
    project.team.max_member_access_for_user_ids(users.map(&:id))
  end
end

UserSerializer.prepend_mod_with('UserSerializer')
