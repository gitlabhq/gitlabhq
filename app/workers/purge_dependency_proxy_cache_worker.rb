# frozen_string_literal: true

class PurgeDependencyProxyCacheWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include Gitlab::Allowable
  idempotent!

  queue_namespace :dependency_proxy
  feature_category :dependency_proxy

  UPDATE_BATCH_SIZE = 100

  def perform(current_user_id, group_id)
    @current_user = User.find_by_id(current_user_id)
    @group = Group.find_by_id(group_id)

    return unless valid?

    @group.dependency_proxy_blobs.each_batch(of: UPDATE_BATCH_SIZE) do |batch|
      batch.update_all(status: :expired)
    end

    @group.dependency_proxy_manifests.each_batch(of: UPDATE_BATCH_SIZE) do |batch|
      batch.update_all(status: :expired)
    end
  end

  private

  def valid?
    return unless @group

    can?(@current_user, :admin_group, @group)
  end
end
