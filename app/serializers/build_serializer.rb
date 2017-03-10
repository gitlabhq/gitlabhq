class BuildSerializer < BaseSerializer
  entity BuildEntity

  def only_status
    tap { @status_only = { only: [{ details: [:status] }] } }
  end

  def represent(resource, opts = {})
    if @status_only.present?
      opts.merge!(@status_only)
    end

    super(resource, opts)
  end
end
