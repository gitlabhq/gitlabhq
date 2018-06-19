# rubocop:disable  Rails5/ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
