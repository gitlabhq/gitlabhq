# frozen_string_literal: true

class RemoveBadDependencyProxyManifests < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # We run destroy on each record because we need the callback to remove
    # the underlying files
    DependencyProxy::Manifest.where.not(content_type: nil).destroy_all # rubocop:disable Cop/DestroyAll
  end

  def down
    # no op
  end
end
