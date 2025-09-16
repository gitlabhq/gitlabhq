# frozen_string_literal: true

class AddNotNullToAnalyticsDevopsAdoptionSegmentsOnNamespaceId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_not_null_constraint(:analytics_devops_adoption_segments, :namespace_id)
  end

  def down
    remove_not_null_constraint(:analytics_devops_adoption_segments, :namespace_id)
  end
end
