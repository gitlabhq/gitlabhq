# frozen_string_literal: true

class BlobPolicy < BasePolicy
  delegate { @subject.project }

  rule { can?(:read_code) }.enable :read_blob
end
