module InternalId
  extend ActiveSupport::Concern

  included do
    validate :set_iid, on: :create
    validates :iid, presence: true, numericality: true
  end

  def set_iid
    records = project.send(self.class.name.tableize)
    records = records.with_deleted if self.paranoid?
    max_iid = records.maximum(:iid)

    self.iid = max_iid.to_i + 1
  end

  def to_param
    iid.to_s
  end
end
