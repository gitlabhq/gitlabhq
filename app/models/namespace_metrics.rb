class NamespaceMetrics < ActiveRecord::Base
  belongs_to :namespace

  validates :namespace, presence: true
end
