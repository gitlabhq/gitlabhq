class GeoNodeKey < Key
  has_one :geo_node

  def orphaned?
    self.geo_nodes.length == 0
  end

  def almost_orphaned?
    self.geo_nodes.length == 1
  end

  def destroyed_when_orphaned?
    true
  end
end
