# == Schema Information
#
# Table name: geo_nodes
#
#  id                :integer          not null, primary key
#  schema            :string
#  host              :string
#  port              :integer
#  relative_url_root :string
#  primary           :boolean
#

class GeoNode < ActiveRecord::Base
  default_value_for :schema, 'http'
  default_value_for :port, 80
  default_value_for :relative_url_root, ''
  default_value_for :primary, false

  validates :host, host: true, presence: true, uniqueness: { case_sensitive: false, scope: :port }
  validates :primary, uniqueness: { message: 'primary node already exists' }, if: :primary
  validates :schema, inclusion: %w(http https)

  def uri
    URI.parse("#{schema}://#{host}:#{port}/#{relative_url_root}")
  end
end
