module NonatomicInternalId
  extend ActiveSupport::Concern

  included do
    validate :set_iid, on: :create
    validates :iid, presence: true, numericality: true
  end

  def set_iid
    if iid.blank?
      parent = project || group
      records = parent.public_send(self.class.name.tableize) # rubocop:disable GitlabSecurity/PublicSend
      max_iid = records.maximum(:iid)

      self.iid = max_iid.to_i + 1
    end
  end

  def to_param
    iid.to_s
  end
end
