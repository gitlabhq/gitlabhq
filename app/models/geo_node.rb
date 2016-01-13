# == Schema Information
#
# Table name: geo_nodes
#
#  id                :integer          not null, primary key
#  host              :string
#  relative_url_root :string
#  primary           :boolean
#

class GeoNode < ActiveRecord::Base
  default_value_for :primary, false
  default_value_for :relative_url_root, ''

  validates :host, hostname: true, presence: true, uniqueness: { case_sensitive: false }
  validates :primary, uniqueness: { message: 'primary node already exists' }, if: :primary
end
