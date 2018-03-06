module AtomicInternalId
  extend ActiveSupport::Concern

  included do
    before_validation(on: :create) do
      set_iid
    end

    validates :iid, presence: true, numericality: true
  end

  def set_iid
    self.iid = InternalId.generate_next(self.project, :issues) if iid.blank?
  end

  def to_param
    iid.to_s
  end
end
