class Geo::BaseRegistry < ActiveRecord::Base
  include ::EE::Geo::GeoTrackable

  self.abstract_class = true
end
