class Timelog < ActiveRecord::Base
  belongs_to :trackable, polymorphic: true
end
