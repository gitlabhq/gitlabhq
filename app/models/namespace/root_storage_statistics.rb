# frozen_string_literal: true

class Namespace::RootStorageStatistics < ApplicationRecord
  self.primary_key = :namespace_id

  belongs_to :namespace
  has_one :route, through: :namespace

  delegate :all_projects, to: :namespace
end
