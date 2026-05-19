# frozen_string_literal: true

SHARDING_KEY_MAP = {
  'projects' => { 'organization_id' => :organizations }
}.freeze

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Project < ApplicationRecord
  has_many :issues
end

class Issue < ApplicationRecord
end

class Snippet < ApplicationRecord
end

class Organization < ApplicationRecord
end

class Feature < ApplicationRecord
end

class UserDetail < ApplicationRecord
end
