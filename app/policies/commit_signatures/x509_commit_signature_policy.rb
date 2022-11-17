# frozen_string_literal: true

module CommitSignatures
  class X509CommitSignaturePolicy < BasePolicy
    delegate { @subject.project }
  end
end
