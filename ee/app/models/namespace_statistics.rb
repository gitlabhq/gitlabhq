class NamespaceStatistics < ActiveRecord::Base
  belongs_to :namespace

  validates :namespace, presence: true

  def shared_runners_minutes
    shared_runners_seconds.to_i / 60
  end
end
