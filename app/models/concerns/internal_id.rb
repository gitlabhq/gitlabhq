module InternalId
  extend ActiveSupport::Concern

  included do
    validate :set_iid, on: :create
    validates :iid, presence: true, numericality: true
  end

  def set_iid
    max_iid = case self.class
              when Issue, MergeRequest
                project.send(self.class.name.tableize).with_deleted.maximum(:iid)
              else
                project.send(self.class.name.tableize).maximum(:iid)
              end
    self.iid = max_iid.to_i + 1
  end

  def to_param
    iid.to_s
  end
end
