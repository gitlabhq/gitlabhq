# frozen_string_literal: true

class PurgeDependencyProxyCacheWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include Gitlab::Allowable
  idempotent!

  queue_namespace :dependency_proxy
  feature_category :dependency_proxy

  def perform(current_user_id, group_id)
    @current_user = User.find_by_id(current_user_id)
    @group = Group.find_by_id(group_id)

    return unless valid?

    @group.dependency_proxy_blobs.destroy_all # rubocop:disable Cop/DestroyAll
    @group.dependency_proxy_manifests.destroy_all # rubocop:disable Cop/DestroyAll
  end

  private

  def valid?
    return unless @group

    can?(@current_user, :admin_group, @group) && @group.dependency_proxy_feature_available?
  end
end
