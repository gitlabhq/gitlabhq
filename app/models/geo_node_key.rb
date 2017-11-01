class GeoNodeKey < Key
  has_one :geo_node, inverse_of: :geo_node_key

  def orphaned?
    self.geo_nodes.length == 0
  end

  def almost_orphaned?
    self.geo_nodes.length == 1
  end

  def destroyed_when_orphaned?
    true
  end

  # Geo secondary nodes use these keys to get read access to all projects.
  # If the secondary is promoted to a primary, its key is no longer valid.
  #
  # This is necessary because keys are placed in the `~git/.ssh` directory;
  # repository mirroring and other actions that shell out to SSH make use of
  # the same directory. A Geo secondary does not perform any of these actions,
  # but if it is made a primary and the keys are not removed, every user on the
  # GitLab instance will be able to access every project using this key.
  def active?
    geo_node&.secondary?
  end
end
