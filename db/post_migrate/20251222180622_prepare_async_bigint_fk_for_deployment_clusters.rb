# frozen_string_literal: true

class PrepareAsyncBigintFkForDeploymentClusters < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    # no-op duplicated in
    # db/post_migrate/20251224150011_prepare_async_bigint_fk_for_deployment_clusters_real.rb
    # due to https://gitlab.com/gitlab-org/gitlab/-/issues/584816#note_2973390014
  end
end
