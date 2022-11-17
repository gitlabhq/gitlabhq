# frozen_string_literal: true

module CommitSignatures
  class GpgSignaturePolicy < BasePolicy
    delegate { @subject.project }
  end
end
