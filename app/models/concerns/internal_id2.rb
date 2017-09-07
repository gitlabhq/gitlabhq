module InternalId2
  extend ActiveSupport::Concern

  included do
    after_commit :set_iid, on: :create
  end

  def set_iid
    parent = project || group
    records = parent.public_send(table_name) # rubocop:disable GitlabSecurity/PublicSend
    records = records.with_deleted if self.paranoid?

    begin
      retries ||= 0
      max_iid = records.maximum(:iid) || -1
      update_columns(iid: max_iid.to_i + 1) # Avoid infinite loop
    rescue ActiveRecord::RecordNotUnique => e
      if (retries += 1) < 3
        retry
      else
        raise ActiveRecord::RecordInvalid
      end
    end
  end

  def table_name
    self.class.name.deconstantize.split("::").map(&:underscore).join('_')
      + self.class.name.demodulize.tableize
  end
end
