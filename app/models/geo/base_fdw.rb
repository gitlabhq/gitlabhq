class Geo::BaseFdw < ActiveRecord::Base
  include ::EE::Geo::GeoTrackable

  self.abstract_class = true
end
