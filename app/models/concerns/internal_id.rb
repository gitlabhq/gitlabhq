module InternalId
  extend ActiveSupport::Concern

  included do
    validate :set_iid, on: :create
    validates :iid, presence: true, numericality: true
  end

  def set_iid
    if iid.blank?
      parent = project || group
      records = parent.public_send(table_name) # rubocop:disable GitlabSecurity/PublicSend
      records = records.with_deleted if self.paranoid?
      max_iid = records.maximum(:iid)

      self.iid = max_iid.to_i + 1
    end
  end

  def to_param
    iid.to_s
  end

  def table_name
    self.class.name.deconstantize.split("::").map(&:underscore).join('_')
      + self.class.name.demodulize.tableize
  end
end
