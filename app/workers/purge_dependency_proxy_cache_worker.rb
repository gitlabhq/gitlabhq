# frozen_string_literal: true

class PurgeDependencyProxyCacheWorker
  include ApplicationWorker
  include DependencyProxy::Expireable

  data_consistency :delayed

  sidekiq_options retry: 3
  include Gitlab::Allowable
  idempotent!

  queue_namespace :dependency_proxy
  feature_category :virtual_registry

  def perform(current_user_id, group_id)
    @current_user = User.find_by_id(current_user_id)
    @group = Group.find_by_id(group_id)

    return unless valid?

    expire_artifacts(@group.dependency_proxy_blobs)
    expire_artifacts(@group.dependency_proxy_manifests)
  end

  private

  def valid?
    return unless @group

    can?(@current_user, :admin_group, @group)
  end
end
