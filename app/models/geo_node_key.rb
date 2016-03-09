# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#  public      :boolean          default(FALSE), not null
#

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
