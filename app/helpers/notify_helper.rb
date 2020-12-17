# frozen_string_literal: true

module NotifyHelper
  def merge_request_reference_link(entity, *args)
    link_to(entity.to_reference, merge_request_url(entity, *args))
  end

  def issue_reference_link(entity, *args, full: false)
    link_to(entity.to_reference(full: full), issue_url(entity, *args))
  end
end
